import std/math

const
  MaxComponent = 100.0
  PiValue = 3.14159265358979323846264338327950288

proc fft8(real: var array[8, float64], imag: var array[8, float64], inverse: bool) =
  const reversed = [0, 4, 2, 6, 1, 5, 3, 7]
  for i in 0 ..< 8:
    let j = reversed[i]
    if i < j:
      swap(real[i], real[j])
      swap(imag[i], imag[j])
  for stage in 1 .. 3:
    let blockSize = 1 shl stage
    let half = blockSize div 2
    for start in countup(0, 8 - blockSize, blockSize):
      for j in 0 ..< half:
        let sign = (if inverse: 1.0 else: -1.0)
        let angle = sign * 2.0 * PiValue * float64(j) / float64(blockSize)
        let wr = cos(angle)
        let wi = sin(angle)
        let even = start + j
        let odd = even + half
        let vr = real[odd] * wr - imag[odd] * wi
        let vi = real[odd] * wi + imag[odd] * wr
        let ur = real[even]
        let ui = imag[even]
        real[even] = ur + vr
        imag[even] = ui + vi
        real[odd] = ur - vr
        imag[odd] = ui - vi
  if inverse:
    for i in 0 ..< 8:
      real[i] /= 8.0
      imag[i] /= 8.0

proc rader_fft*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rader_fft".} =
  const permutation = [1, 2, 4, 3]
  const kernelPower = [1, 3, 4, 2]
  if input.isNil or inputLen != csize_t(10): return -1
  for i in 0 ..< 10:
    let value = input[i]
    if value != value or value < -MaxComponent or value > MaxComponent: return -1
  if output.isNil or outputCapacity < csize_t(10): return -2

  var ar, ai, br, bi: array[8, float64]
  for i in 0 ..< 4:
    ar[i] = input[2 * permutation[i]]
    ai[i] = input[2 * permutation[i] + 1]
    let angle = -2.0 * PiValue * float64(kernelPower[i]) / 5.0
    br[i] = cos(angle)
    bi[i] = sin(angle)
  fft8(ar, ai, false)
  fft8(br, bi, false)
  for i in 0 ..< 8:
    let productReal = ar[i] * br[i] - ai[i] * bi[i]
    let productImag = ar[i] * bi[i] + ai[i] * br[i]
    ar[i] = productReal
    ai[i] = productImag
  fft8(ar, ai, true)

  var result: array[10, float64]
  for n in 0 ..< 5:
    result[0] += input[2 * n]
    result[1] += input[2 * n + 1]
  for k in 1 ..< 5:
    result[2 * k] = input[0]
    result[2 * k + 1] = input[1]
  for i in 0 ..< 4:
    let target = kernelPower[i]
    result[2 * target] += ar[i] + ar[i + 4]
    result[2 * target + 1] += ai[i] + ai[i + 4]
  for i in 0 ..< 10:
    output[i] = result[i]
  10
