## Count a maximum set of non-overlapping half-open activities.
proc activity_selection*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "activity_selection".} =
  if length == 0 or input[0] < 0 or input[0] > 64: return -1
  let count = int(input[0])
  if length != csize_t(1 + 2 * count): return -1
  if count == 0: return 0
  var starts: array[64, int64]
  var finishes: array[64, int64]
  for index in 0 ..< count:
    starts[index] = input[1 + 2 * index]
    finishes[index] = input[2 + 2 * index]
    if starts[index] > finishes[index]: return -1
  var index = 1
  while index < count:
    let start = starts[index]
    let finish = finishes[index]
    var position = index
    while position > 0 and (finishes[position - 1] > finish or
        (finishes[position - 1] == finish and starts[position - 1] > start)):
      starts[position] = starts[position - 1]
      finishes[position] = finishes[position - 1]
      dec position
    starts[position] = start
    finishes[position] = finish
    inc index
  var selected = 1'i64
  var lastFinish = finishes[0]
  for index in 1 ..< count:
    if starts[index] >= lastFinish:
      inc selected
      lastFinish = finishes[index]
  selected
