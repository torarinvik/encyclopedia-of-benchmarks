proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc next_fit_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "next_fit_bin_packing".} =
  if input.isNil or length < 1 or length > 65: return -1
  let n0 = input[0]
  if n0 < 0 or n0 > 64 or int(length) != 1 + int(n0): return -1
  let n = int(n0)
  for i in 0 ..< n:
    let size = input[i + 1]
    if size < 1 or size > 1_000_000: return -1
  var assignments: array[64, int64]
  var bins = 0'i64
  var remaining = 0'i64
  for i in 0 ..< n:
    let size = input[i + 1]
    if bins == 0 or size > remaining:
      assignments[i] = bins
      inc bins
      remaining = 1_000_000 - size
    else:
      assignments[i] = bins - 1
      remaining -= size
  let bytes = 8 * (n + 1)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, bins)
  for i in 0 ..< n: putI64(output, i + 1, assignments[i])
  int64(bytes)
