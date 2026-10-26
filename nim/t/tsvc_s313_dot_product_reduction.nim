import std/math

const MaxN = 64

proc tsvc_s313_dot_product_reduction*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s313_dot_product_reduction".} =
  if input.isNil or length < 3 or length > csize_t(1 + 2 * MaxN): return -1
  let rawN = input[0]
  if not rawN.isFinite or rawN != floor(rawN) or rawN < 1.0 or rawN > float64(MaxN): return -1
  let n = int(rawN)
  if length != csize_t(1 + 2 * n): return -1
  for i in 1 ..< int(length):
    if not input[i].isFinite or input[i] != floor(input[i]) or abs(input[i]) > 1000.0: return -1
  if output.isNil or capacity < 1: return -2
  var sum = 0.0
  for i in 0 ..< n: sum += input[1 + i] * input[1 + n + i]
  output[0] = sum
  1
