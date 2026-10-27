proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc best_fit_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "best_fit_bin_packing".} =
  if input.isNil or length < 1 or length > 65: return -1
  let n0 = input[0]
  if n0 < 0 or n0 > 64 or int(length) != 1 + int(n0): return -1
  let n = int(n0)
  for i in 0 ..< n:
    let size = input[i + 1]
    if size < 1 or size > 1_000_000: return -1
  var loads: array[64, int64]
  var assignments: array[64, int64]
  var bins = 0
  for i in 0 ..< n:
    let size = input[i + 1]
    var selected = bins
    var leastRemaining = 1_000_001'i64
    for bin in 0 ..< bins:
      if loads[bin] + size <= 1_000_000:
        let remaining = 1_000_000 - loads[bin] - size
        if remaining < leastRemaining:
          leastRemaining = remaining
          selected = bin
    if selected == bins:
      loads[bins] = size
      assignments[i] = int64(bins)
      inc bins
    else:
      loads[selected] += size
      assignments[i] = int64(selected)
  let bytes = 8 * (n + 1)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, int64(bins))
  for i in 0 ..< n: putI64(output, i + 1, assignments[i])
  int64(bytes)
