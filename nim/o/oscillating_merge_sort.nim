## Alternating-direction bounded multi-tape merge with backward reads.
const MaxValues = 1024
const MaxParts = 2
const InitialRunSize = 16

proc buildRun(values: ptr UncheckedArray[int64], valueCount, runSize, mergeInputs,
              firstRun, runCount: int, ascending: bool,
              output: ptr UncheckedArray[int64]): int =
  if runCount == 1:
    let start = firstRun * runSize
    result = min(runSize, valueCount - start)
    for i in 0 ..< result: output[i] = values[start + i]
    for i in 1 ..< result:
      let value = output[i]
      var position = i
      while position > 0 and (if ascending: value < output[position - 1]
                              else: value > output[position - 1]):
        output[position] = output[position - 1]
        dec position
      output[position] = value
    return

  var children: array[MaxParts, array[MaxValues, int64]]
  var lengths: array[MaxParts, int]
  var positions: array[MaxParts, int]
  let quotient = runCount div mergeInputs
  let remainder = runCount mod mergeInputs
  var nextRun = firstRun
  var total = 0
  for lane in 0 ..< mergeInputs:
    let childCount = quotient + (if lane < remainder: 1 else: 0)
    if childCount == 0: continue
    lengths[lane] = buildRun(values, valueCount, runSize, mergeInputs,
      nextRun, childCount, not ascending, addr children[lane][0])
    nextRun += childCount
    total += lengths[lane]
  for outIndex in 0 ..< total:
    var bestLane = MaxParts
    var bestValue = 0'i64
    for lane in 0 ..< mergeInputs:
      if positions[lane] >= lengths[lane]: continue
      let candidate = children[lane][lengths[lane] - 1 - positions[lane]]
      if bestLane == MaxParts or (if ascending: candidate < bestValue
                                  else: candidate > bestValue):
        bestLane = lane
        bestValue = candidate
    output[outIndex] = bestValue
    inc positions[bestLane]
  total

proc oscillating_merge_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "oscillating_merge_sort".} =
  if length == 0 or length > csize_t(MaxValues) or values == nil: return
  let count = int(length)
  var sorted: array[MaxValues, int64]
  let runCount = (count + InitialRunSize - 1) div InitialRunSize
  discard buildRun(values, count, InitialRunSize, MaxParts, 0, runCount, true, addr sorted[0])
  for i in 0 ..< count: values[i] = sorted[i]
