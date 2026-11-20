import math

const MaxN = 64
const MaxInputLength = 130
const MaxScalars = 128
const Tau = 6.283185307179586476925286766559

proc stockhamStage(source: var array[MaxScalars, float64],
                   destination: var array[MaxScalars, float64], n, stride: int) =
  for j in 0 ..< n div 2:
    let column = j mod stride
    let group = j div stride
    let base = group * 2 * stride + column
    let angle = -Tau * float64(column) / float64(2 * stride)
    let cosine = cos(angle)
    let sine = sin(angle)
    let left = 2 * j
    let right = 2 * (j + n div 2)
    let productReal = cosine * source[right] - sine * source[right + 1]
    let productImag = cosine * source[right + 1] + sine * source[right]
    let firstReal = source[left]
    let firstImag = source[left + 1]
    let outLeft = 2 * base
    let outRight = 2 * (base + stride)
    destination[outLeft] = firstReal + productReal
    destination[outLeft + 1] = firstImag + productImag
    destination[outRight] = firstReal - productReal
    destination[outRight + 1] = firstImag - productImag

proc stockham_autosort_radix2_fft*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc: "stockham_autosort_radix2_fft".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength: return -1
  for i in 0 ..< int(inputLength):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let nValue = input[0]
  if nValue < 1.0 or nValue > float64(MaxN) or floor(nValue) != nValue: return -1
  let n = int(nValue)
  if (n and (n - 1)) != 0 or inputLength != csize_t(1 + 2 * n): return -1
  for i in 0 ..< 2 * n:
    if input[i + 1] < -8.0 or input[i + 1] > 8.0: return -1

  var first, second: array[MaxScalars, float64]
  for i in 0 ..< 2 * n: first[i] = input[i + 1]
  var sourceIsFirst = true
  var stride = 1
  while stride < n:
    if sourceIsFirst:
      stockhamStage(first, second, n, stride)
    else:
      stockhamStage(second, first, n, stride)
    sourceIsFirst = not sourceIsFirst
    stride *= 2

  let needed = 2 * n
  if output == nil or outputCapacity < csize_t(needed): return -2
  for i in 0 ..< needed:
    output[i] = if sourceIsFirst: first[i] else: second[i]
  int64(needed)
