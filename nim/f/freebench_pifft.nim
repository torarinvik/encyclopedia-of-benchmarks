import std/math

const
  FftSize = 8
  Base = 1000'i64
  Scale = 1_000_000'i64

proc fftTransform(real: var array[FftSize, float64],
                  imag: var array[FftSize, float64], inverse: bool) =
  const reversed = [0, 4, 2, 6, 1, 5, 3, 7]
  for i in 0 ..< FftSize:
    let j = reversed[i]
    if i < j:
      swap(real[i], real[j])
      swap(imag[i], imag[j])
  for stage in 1 .. 3:
    let blockSize = 1 shl stage
    let half = blockSize div 2
    for start in countup(0, FftSize - blockSize, blockSize):
      for offset in 0 ..< half:
        let rootReal = if blockSize == 2: -1.0 elif blockSize == 4: 0.0 else: 0.7071067811865476
        let rootImag = if blockSize == 2: 0.0 elif blockSize == 4: (if inverse: 1.0 else: -1.0) else: (if inverse: 0.7071067811865476 else: -0.7071067811865476)
        var twiddleReal = 1.0
        var twiddleImag = 0.0
        for _ in 0 ..< offset:
          let nextReal = twiddleReal * rootReal - twiddleImag * rootImag
          twiddleImag = twiddleReal * rootImag + twiddleImag * rootReal
          twiddleReal = nextReal
        let even = start + offset
        let odd = even + half
        let oddReal = real[odd] * twiddleReal - imag[odd] * twiddleImag
        let oddImag = real[odd] * twiddleImag + imag[odd] * twiddleReal
        let evenReal = real[even]
        let evenImag = imag[even]
        real[even] = evenReal + oddReal
        imag[even] = evenImag + oddImag
        real[odd] = evenReal - oddReal
        imag[odd] = evenImag - oddImag
  if inverse:
    for i in 0 ..< FftSize:
      real[i] /= float64(FftSize)
      imag[i] /= float64(FftSize)

proc fftMultiplyFixed(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  var sign = 1'i64
  if left < 0: sign = -sign; left = -left
  if right < 0: sign = -sign; right = -right
  var leftReal, leftImag, rightReal, rightImag: array[FftSize, float64]
  for i in 0 ..< 3:
    leftReal[i] = float64(left mod Base)
    rightReal[i] = float64(right mod Base)
    left = left div Base
    right = right div Base
  fftTransform(leftReal, leftImag, false)
  fftTransform(rightReal, rightImag, false)
  for i in 0 ..< FftSize:
    let productReal = leftReal[i] * rightReal[i] - leftImag[i] * rightImag[i]
    let productImag = leftReal[i] * rightImag[i] + leftImag[i] * rightReal[i]
    leftReal[i] = productReal
    leftImag[i] = productImag
  fftTransform(leftReal, leftImag, true)
  var product = 0'i64
  var place = 1'i64
  for i in 0 ..< 5:
    let coefficient = int64(leftReal[i] + 0.5)
    product += coefficient * place
    place *= Base
  let rounded = (product + Scale div 2) div Scale
  sign * rounded

proc fixedSqrt(value: int64): int64 =
  if value <= 0: return 0
  let radicand = value * Scale
  var root = radicand
  while true:
    let next = (root + radicand div root) div 2
    if next >= root: break
    root = next
  let lowerError = radicand - root * root
  let upperError = (root + 1) * (root + 1) - radicand
  if upperError < lowerError: root + 1 else: root

proc fixedHalf(value: int64): int64 =
  if value < 0: -((-value) div 2) else: value div 2

proc fixedDivide(numerator, denominator: int64): int64 =
  if denominator <= 0: return 0
  let scaled = numerator * Scale
  if scaled < 0: -((-scaled + denominator div 2) div denominator)
  else: (scaled + denominator div 2) div denominator

proc freebench_pifft*(nfft: int64): int64 {.cdecl, exportc: "freebench_pifft".} =
  if nfft != int64(FftSize): return -1
  var c = fixedSqrt(125_000)
  var a = Scale + 3 * c
  var b = fixedSqrt(a)
  var e = b - 625_000
  b *= 2
  c = e - c
  a += e
  var npow = 4'i64
  for _ in 0 ..< 8:
    npow *= 2
    e = fixedHalf(a + b)
    b = fixedSqrt(fftMultiplyFixed(a, b))
    e -= b
    b *= 2
    c -= e
    a = e + b
    if e >= -1 and e <= 1: break
  e = fixedHalf(e)
  e = fftMultiplyFixed(e, e)
  a += b
  let numerator = fftMultiplyFixed(a, a) - e - fixedHalf(e)
  let denominator = fftMultiplyFixed(a, c) - e
  var pi = fixedDivide(numerator, denominator)
  pi = (pi + npow div 2) div npow
  (pi + 500) div 1000
