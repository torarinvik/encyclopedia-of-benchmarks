import std/math

const MaxN = 64

proc tsvc_s111_odd_index_neighbor_update*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s111_odd_index_neighbor_update".} =
  if input.isNil or length < 3 or length > csize_t(129): return -1
  let rawN = input[0]
  if not rawN.isFinite or rawN != floor(rawN) or rawN < 1.0 or rawN > float64(MaxN): return -1
  let n = int(rawN)
  if length != csize_t(1 + 2 * n): return -1
  for i in 1 ..< int(length):
    if not input[i].isFinite or input[i] != floor(input[i]) or abs(input[i]) > 1000.0: return -1
  if output.isNil or capacity < csize_t(n): return -2
  for i in 0 ..< n: output[i] = input[1 + i]
  var i = 1
  while i < n:
    output[i] = input[i] + input[1 + n + i]
    i += 2
  int64(n)
