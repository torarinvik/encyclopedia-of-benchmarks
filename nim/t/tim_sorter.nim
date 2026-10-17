const MaxItems = 512
const MinMerge = 32
const MaxParseableInputLength = 1026
const HashMultiplier = 1000003'i64
const HashModulus = 1000000007'i64
const MaxRunStack = 85

type Item = object
  key: int64
  id: int64

proc binarySort(items: var array[MaxItems, Item], start, finish, firstArg: int) =
  var first = firstArg
  if first >= finish or first <= start: first = start + 1
  while first < finish:
    let target = items[first]
    var left = start
    var right = first
    while left < right:
      let middle = (left + right) shr 1
      if target.key < items[middle].key: right = middle
      else: left = middle + 1
    var cursor = first
    while cursor > left:
      items[cursor] = items[cursor - 1]
      dec cursor
    items[left] = target
    inc first

proc countRunAndMakeAscending(items: var array[MaxItems, Item], start, length: int): int =
  var finish = start + 1
  if finish == length: return 1
  if items[finish].key < items[start].key:
    inc finish
    while finish < length and items[finish].key < items[finish - 1].key: inc finish
    var left = start
    var right = finish - 1
    while left < right:
      swap(items[left], items[right])
      inc left
      dec right
  else:
    inc finish
    while finish < length and items[finish].key >= items[finish - 1].key: inc finish
  finish - start

proc minRunLength(totalArg: int): int =
  var total = totalArg
  var remainder = 0
  while total >= MinMerge:
    remainder = remainder or (total and 1)
    total = total shr 1
  total + remainder

proc mergeAt(items: var array[MaxItems, Item], temp: var array[MaxItems, Item],
             runBase: var array[MaxRunStack, int], runLength: var array[MaxRunStack, int],
             stackSize: var int, index: int) =
  let baseA = runBase[index]
  let lenA = runLength[index]
  let baseB = runBase[index + 1]
  let lenB = runLength[index + 1]
  runLength[index] = lenA + lenB
  if index == stackSize - 3:
    runBase[index + 1] = runBase[index + 2]
    runLength[index + 1] = runLength[index + 2]
  dec stackSize
  for i in 0 ..< lenA: temp[i] = items[baseA + i]
  var left = 0
  var right = baseB
  var dest = baseA
  let endB = baseB + lenB
  while left < lenA and right < endB:
    if items[right].key < temp[left].key:
      items[dest] = items[right]
      inc right
    else:
      items[dest] = temp[left]
      inc left
    inc dest
  while left < lenA:
    items[dest] = temp[left]
    inc left
    inc dest

proc mergeCollapse(items: var array[MaxItems, Item], temp: var array[MaxItems, Item],
                   runBase: var array[MaxRunStack, int], runLength: var array[MaxRunStack, int],
                   stackSize: var int) =
  while stackSize > 1:
    var n = stackSize - 2
    if n > 0 and runLength[n - 1] <= runLength[n] + runLength[n + 1]:
      if runLength[n - 1] < runLength[n + 1]: dec n
      mergeAt(items, temp, runBase, runLength, stackSize, n)
    elif runLength[n] <= runLength[n + 1]:
      mergeAt(items, temp, runBase, runLength, stackSize, n)
    else:
      break

proc timSort(items: var array[MaxItems, Item], length: int) =
  if length < MinMerge:
    binarySort(items, 0, length, 0)
    return
  let minRun = minRunLength(length)
  var runBase: array[MaxRunStack, int]
  var runLength: array[MaxRunStack, int]
  var temp: array[MaxItems, Item]
  var stackSize = 0
  var start = 0
  var remaining = length
  while remaining > 0:
    var currentRun = countRunAndMakeAscending(items, start, length)
    if currentRun < minRun:
      let force = min(minRun, remaining)
      binarySort(items, start, start + force, start + currentRun)
      currentRun = force
    runBase[stackSize] = start
    runLength[stackSize] = currentRun
    inc stackSize
    mergeCollapse(items, temp, runBase, runLength, stackSize)
    start += currentRun
    remaining -= currentRun
  while stackSize > 1:
    var n = stackSize - 2
    if n > 0 and runLength[n - 1] < runLength[n + 1]: dec n
    mergeAt(items, temp, runBase, runLength, stackSize, n)

proc tim_sorter_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tim_sorter_benchmark".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0 or input[0] > MaxItems: return -1
  let count = int(input[0])
  if length != csize_t(1 + 2 * count): return -1
  var items: array[MaxItems, Item]
  var seen: array[MaxItems, bool]
  for index in 0 ..< count:
    let key = input[1 + 2 * index]
    let id = input[2 + 2 * index]
    if key < -1000 or key > 1000 or id < 0 or id >= int64(count): return -1
    if seen[int(id)]: return -1
    seen[int(id)] = true
    items[index] = Item(key: key, id: id)
  timSort(items, count)
  var checksum = 0'i64
  for index in 0 ..< count:
    let token = (items[index].key + 1000) * 513 + items[index].id + 1
    checksum = (checksum * HashMultiplier + token) mod HashModulus
  checksum
