import std/math

const MaxN = 64
const MaxSteps = 8
const MaxInputLength = 2 + 4 * MaxN
const Tau = 6.28318530717958647692528676655900577

proc boundedInteger(value, minimum, maximum: float64): bool =
  value == value and value >= minimum and value <= maximum and trunc(value) == value

proc fft(real, imag: var array[MaxN, float64], n: int, inverse: bool) =
  var reverse = 0
  for position in 1 ..< n:
    var bit = n shr 1
    while bit != 0 and (reverse and bit) != 0:
      reverse = reverse xor bit
      bit = bit shr 1
    reverse = reverse xor bit
    if position < reverse:
      swap(real[position], real[reverse])
      swap(imag[position], imag[reverse])
  var block = 2
  while block <= n:
    let direction = if inverse: 1.0 else: -1.0
    let angle = direction * Tau / float64(block)
    let stepReal = cos(angle)
    let stepImag = sin(angle)
    var start = 0
    while start < n:
      var weightReal = 1.0
      var weightImag = 0.0
      for offset in 0 ..< block div 2:
        let first = start + offset
        let second = first + block div 2
        let productReal = weightReal * real[second] - weightImag * imag[second]
        let productImag = weightReal * imag[second] + weightImag * real[second]
        let firstReal = real[first]
        let firstImag = imag[first]
        real[first] = firstReal + productReal
        imag[first] = firstImag + productImag
        real[second] = firstReal - productReal
        imag[second] = firstImag - productImag
        let nextReal = weightReal * stepReal - weightImag * stepImag
        weightImag = weightReal * stepImag + weightImag * stepReal
        weightReal = nextReal
      start += block
    block *= 2
  if inverse:
    for i in 0 ..< n:
      real[i] /= float64(n)
      imag[i] /= float64(n)

proc normalize(real, imag: var array[MaxN, float64], n: int) =
  var normSquared = 0.0
  for i in 0 ..< n: normSquared += real[i] * real[i] + imag[i] * imag[i]
  let norm = sqrt(normSquared)
  for i in 0 ..< n:
    real[i] /= norm
    imag[i] /= norm

proc split_operator_imaginary_time*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "split_operator_imaginary_time".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  if not boundedInteger(input[0], 2.0, float64(MaxN))
      or not boundedInteger(input[1], 0.0, float64(MaxSteps)): return -1
  let n = int(input[0])
  let steps = int(input[1])
  if (n and (n - 1)) != 0 or length != csize_t(2 + 4 * n): return -1
  let momentumStart = 2 + n
  let stateStart = 2 + 2 * n
  var normSquared = 0.0
  for i in 0 ..< n:
    let position = input[2 + i]
    let momentum = input[momentumStart + i]
    let realValue = input[stateStart + 2 * i]
    let imagValue = input[stateStart + 2 * i + 1]
    if position != position or position < 0.25 or position > 1.0
        or momentum != momentum or momentum < 0.25 or momentum > 1.0
        or realValue != realValue or realValue < -1.0 or realValue > 1.0
        or imagValue != imagValue or imagValue < -1.0 or imagValue > 1.0: return -1
    normSquared += realValue * realValue + imagValue * imagValue
  if not normSquared > 0.0: return -1
  let outputCount = 2 * n
  if output.isNil or capacity < csize_t(outputCount): return -2

  var real, imag: array[MaxN, float64]
  for i in 0 ..< n:
    real[i] = input[stateStart + 2 * i]
    imag[i] = input[stateStart + 2 * i + 1]
  normalize(real, imag, n)
  for _ in 0 ..< steps:
    for i in 0 ..< n:
      real[i] *= input[2 + i]
      imag[i] *= input[2 + i]
    fft(real, imag, n, false)
    for i in 0 ..< n:
      real[i] *= input[momentumStart + i]
      imag[i] *= input[momentumStart + i]
    fft(real, imag, n, true)
    for i in 0 ..< n:
      real[i] *= input[2 + i]
      imag[i] *= input[2 + i]
    normalize(real, imag, n)
  for i in 0 ..< n:
    output[2 * i] = real[i]
    output[2 * i + 1] = imag[i]
  int64(outputCount)
