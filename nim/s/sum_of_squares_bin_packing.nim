proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc sum_of_squares_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sum_of_squares_bin_packing".} =
  if input.isNil or length < 2 or length > 66: return -1
  let capacity0 = input[0]; let n0 = input[1]
  if capacity0 < 1 or capacity0 > 64 or n0 < 0 or n0 > 64 or int(length) != 2 + int(n0): return -1
  let n = int(n0)
  for item in 0 ..< n:
    let size = input[item + 2]
    if size < 1 or size > capacity0: return -1
  var histogram: array[65, int64]
  var loads: array[64, int64]
  var assignments: array[64, int64]
  var bins = 0
  var score = 0'i64
  for item in 0 ..< n:
    let size = input[item + 2]
    var selected = bins
    var bestScore = high(int64)
    for bin in 0 ..< bins:
      let fromLoad = loads[bin]
      let toLoad = fromLoad + size
      if toLoad > capacity0: continue
      var candidate = score
      if fromLoad < capacity0:
        let old = histogram[int(fromLoad)]
        candidate += (old - 1) * (old - 1) - old * old
      if toLoad < capacity0:
        let old = histogram[int(toLoad)]
        candidate += (old + 1) * (old + 1) - old * old
      if candidate < bestScore:
        bestScore = candidate
        selected = bin
    var newScore = score
    if size < capacity0:
      let old = histogram[int(size)]
      newScore += (old + 1) * (old + 1) - old * old
    if newScore < bestScore:
      bestScore = newScore
      selected = bins
    if selected == bins:
      loads[bins] = size
      assignments[item] = int64(bins)
      if size < capacity0: inc histogram[int(size)]
      inc bins
    else:
      let fromLoad = loads[selected]
      let toLoad = fromLoad + size
      if fromLoad < capacity0: dec histogram[int(fromLoad)]
      if toLoad < capacity0: inc histogram[int(toLoad)]
      loads[selected] = toLoad
      assignments[item] = int64(selected)
    score = bestScore
  let bytes = 8 * (n + 1)
  if output.isNil or int(outputCapacity) < bytes: return -2
  putI64(output, 0, int64(bins))
  for item in 0 ..< n: putI64(output, item + 1, assignments[item])
  int64(bytes)
