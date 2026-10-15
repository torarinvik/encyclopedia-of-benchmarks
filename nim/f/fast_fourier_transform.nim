import std/math

type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc quantize(value: float64): int64 =
  let scaled = value * 1_000_000.0
  if scaled >= 0.0: return int64(scaled + 0.5)
  int64(scaled - 0.5)

proc transform(real: var array[64, float64], imag: var array[64, float64], n: int) =
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
    let angle = 6.283185307179586476925286766559 / float64(block)
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

proc fast_fourier_transform*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "fast_fourier_transform".} =
  if values == nil or length < 2 or length > 65: return -1
  let rawN = values[0]
  if rawN < 1 or rawN > 64 or (rawN and (rawN - 1)) != 0: return -1
  let n = int(rawN)
  if length != csize_t(n + 1): return -1
  for index in 0 ..< n:
    if values[index + 1] < -1000 or values[index + 1] > 1000: return -1
  let byteCount = 16 * n
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  var real: array[64, float64]
  var imag: array[64, float64]
  for index in 0 ..< n: real[index] = float64(values[index + 1])
  transform(real, imag, n)
  for index in 0 ..< n:
    storeI64Le(output, 16 * index, quantize(real[index]))
    storeI64Le(output, 16 * index + 8, quantize(imag[index]))
  int64(byteCount)
