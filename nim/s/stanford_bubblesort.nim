const MinRuns = 1'i64
const MaxRuns = 100'i64
const ElementCount = 500
const MaxOutputBytes = 700

proc buildAndSortPass(run: int): tuple[value: int32, endpointError: bool] =
  var sortlist: array[ElementCount + 1, int32]
  var biggest = 0'i32
  var littlest = 0'i32
  var seed = 74755'i64
  for index in 1 .. ElementCount:
    seed = (seed * 1309 + 13849) and 65535
    let temp = seed
    sortlist[index] = int32(temp - (temp div 100000) * 100000 - 50000)
    if sortlist[index] > biggest: biggest = sortlist[index]
    elif sortlist[index] < littlest: littlest = sortlist[index]
  var top = ElementCount
  while top > 1:
    var index = 1
    while index < top:
      if sortlist[index] > sortlist[index + 1]:
        swap(sortlist[index], sortlist[index + 1])
      inc index
    dec top
  (sortlist[run + 1], sortlist[1] != littlest or sortlist[ElementCount] != biggest)

proc appendText(buffer: var array[MaxOutputBytes, uint8], used: var int, text: string) =
  for ch in text:
    buffer[used] = uint8(ord(ch))
    inc used

proc appendInteger(buffer: var array[MaxOutputBytes, uint8], used: var int, value: int32) =
  var remaining = value
  if remaining < 0:
    buffer[used] = uint8(ord('-'))
    inc used
    remaining = -remaining
  var reverse: array[12, uint8]
  var count = 0
  while true:
    reverse[count] = uint8(48 + remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reverse[count]
    inc used

proc stanford_bubblesort*(runs: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_bubblesort".} =
  if runs < MinRuns or runs > MaxRuns: return -1
  if output.isNil: return -2
  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  for run in 0 ..< int(runs):
    let item = buildAndSortPass(run)
    if item.endpointError: appendText(staged, used, "Error3 in Bubble.\n")
    appendInteger(staged, used, item.value)
    appendText(staged, used, "\n")
  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
