proc pairwise_iteration*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "pairwise_iteration".} =
  if v.isNil or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != csize_t(v[0] + 1): return -1
  let count = int(v[0])
  for i in 0..<count: if v[i + 1] < -1_000_000 or v[i + 1] > 1_000_000: return -1
  let bytes = max(0, count - 1) * 16
  if csize_t(bytes) > capacity or (bytes > 0 and output.isNil): return -2
  var k = 0
  for i in 0..<max(0, count - 1):
    for x in [v[i + 1], v[i + 2]]:
      let bits = cast[uint64](x)
      for b in 0..7: output[k] = uint8((bits shr (8 * b)) and 255); inc k
  int64(bytes)
