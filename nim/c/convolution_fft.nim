import std/math

type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

const MaxInputLength = 131
const Pi = 3.14159265358979323846264338327950288

proc writeF64Le(output: U8Output, offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc transform(real: var array[128, float64], imag: var array[128, float64], n: int, inverse: bool) =
  var reverse = 0
  for position in 1 ..< n:
    var bit = n shr 1
    while (reverse and bit) != 0:
      reverse = reverse xor bit
      bit = bit shr 1
    reverse = reverse xor bit
    if position < reverse:
      swap(real[position], real[reverse])
      swap(imag[position], imag[reverse])
  var block = 2
  while block <= n:
    let direction = if inverse: -1.0 else: 1.0
    let angle = -2.0 * Pi / float64(block) * direction
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
    for index in 0 ..< n:
      real[index] /= float64(n)
      imag[index] /= float64(n)

proc convolution_fft*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "convolution_fft".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let rawA = input[0]
  let rawB = input[1]
  if rawA < 1 or rawA > 64 or rawB < 1 or rawB > 64: return -1
  let aCount = int(rawA)
  let bCount = int(rawB)
  if int(length) != 2 + aCount + bCount: return -1
  for index in 0 ..< aCount + bCount:
    if input[index + 2] < -64 or input[index + 2] > 64: return -1
  let resultCount = aCount + bCount - 1
  let byteCount = resultCount * 16
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  var fftLength = 1
  while fftLength < resultCount: fftLength *= 2
  var aReal, aImag, bReal, bImag, productReal, productImag: array[128, float64]
  for index in 0 ..< aCount: aReal[index] = float64(input[index + 2]) / 16.0
  for index in 0 ..< bCount: bReal[index] = float64(input[aCount + index + 2]) / 16.0
  transform(aReal, aImag, fftLength, false)
  transform(bReal, bImag, fftLength, false)
  for index in 0 ..< fftLength:
    productReal[index] = aReal[index] * bReal[index] - aImag[index] * bImag[index]
    productImag[index] = aReal[index] * bImag[index] + aImag[index] * bReal[index]
  transform(productReal, productImag, fftLength, true)
  for index in 0 ..< resultCount:
    writeF64Le(output, index * 16, productReal[index])
    writeF64Le(output, index * 16 + 8, productImag[index])
  int64(byteCount)
