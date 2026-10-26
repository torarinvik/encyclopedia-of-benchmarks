import std/math

proc tsvc_s451_sincos_vector_map*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s451_sincos_vector_map".} =
  if input.isNil or length < 3 or length > csize_t(129): return -1
  let rawN = input[0]
  if not rawN.isFinite or rawN != floor(rawN) or rawN < 1.0 or rawN > 64.0: return -1
  let n = int(rawN)
  if length != csize_t(1 + 2*n): return -1
  for i in 1 ..< int(length):
    if not input[i].isFinite or abs(input[i]) > 10.0: return -1
  if output.isNil or capacity < csize_t(n): return -2
  for i in 0 ..< n: output[i] = sin(input[1+i]) + cos(input[1+n+i])
  int64(n)
