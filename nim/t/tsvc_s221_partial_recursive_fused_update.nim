import std/math

proc tsvc_s221_partial_recursive_fused_update*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s221_partial_recursive_fused_update".} =
  if input.isNil or length < 5 or length > csize_t(257): return -1
  let rawN = input[0]
  if not rawN.isFinite or rawN != floor(rawN) or rawN < 1.0 or rawN > 64.0: return -1
  let n = int(rawN)
  if length != csize_t(1 + 4*n): return -1
  for i in 1 ..< int(length):
    if not input[i].isFinite or input[i] != floor(input[i]) or abs(input[i]) > 2.0: return -1
  let required = 2*n
  if output.isNil or capacity < csize_t(required): return -2
  for i in 0 ..< n:
    output[i] = input[1+i]
    output[n+i] = input[1+n+i]
  for i in 1 ..< n:
    output[i] = output[i] + input[1+2*n+i] * input[1+3*n+i]
    output[n+i] = (output[n+i-1] + output[i]) + input[1+3*n+i]
  int64(required)
