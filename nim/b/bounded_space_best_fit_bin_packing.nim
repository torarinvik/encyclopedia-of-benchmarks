proc bsbPutI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc bounded_space_best_fit_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bounded_space_best_fit_bin_packing".} =
  if input.isNil or length < 1 or length > 65: return -1
  let n0 = input[0]
  if n0 < 0 or n0 > 64 or int(length) != 1 + int(n0): return -1
  let n = int(n0)
  for item in 0 ..< n:
    if input[item + 1] < 1 or input[item + 1] > 1000000: return -1
  var loads: array[64, int64]
  var assignments: array[64, int64]
  var open: array[64, bool]
  var bins = 0
  for item in 0 ..< n:
    let size = input[item + 1]
    var selected = bins
    var leastRemaining = 1000001'i64
    for bin in 0 ..< bins:
      if open[bin] and loads[bin] + size <= 1000000:
        let remaining = 1000000 - loads[bin] - size
        if remaining < leastRemaining:
          leastRemaining = remaining
          selected = bin
    if selected == bins:
      loads[bins] = size
      open[bins] = size < 1000000
      assignments[item] = int64(bins)
      inc bins
    else:
      loads[selected] += size
      assignments[item] = int64(selected)
      if loads[selected] == 1000000: open[selected] = false
    var partialOpen = 0
    for bin in 0 ..< bins:
      if open[bin]: inc partialOpen
    while partialOpen > 2:
      var weakest = bins
      for bin in 0 ..< bins:
        if open[bin] and (weakest == bins or loads[bin] < loads[weakest] or (loads[bin] == loads[weakest] and bin > weakest)):
          weakest = bin
      open[weakest] = false
      dec partialOpen
  let bytes = 8 * (n + 1)
  if output.isNil or int(outputCapacity) < bytes: return -2
  bsbPutI64(output, 0, int64(bins))
  for item in 0 ..< n: bsbPutI64(output, item + 1, assignments[item])
  int64(bytes)
