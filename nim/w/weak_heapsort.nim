const MaxValues = 256
const MaxInputLength = 258

proc distinguishedAncestor(index: int, reverse: var array[MaxValues, bool]): int =
  var node = index
  while node > 0:
    let parent = node div 2
    if (node mod 2 == 0 and not reverse[parent]) or (node mod 2 == 1 and reverse[parent]):
      node = parent
    else:
      break
  node div 2

proc join(values: var array[MaxValues, int64], reverse: var array[MaxValues, bool], ancestor, node: int) =
  if values[ancestor] < values[node]:
    swap(values[ancestor], values[node])
    reverse[node] = not reverse[node]

proc siftDown(values: var array[MaxValues, int64], reverse: var array[MaxValues, bool], activeSize: int) =
  var node = 1
  if reverse[0]: node = 0
  if node >= activeSize: return
  while 2 * node + (if reverse[node]: 1 else: 0) < activeSize:
    node = 2 * node + (if reverse[node]: 1 else: 0)
  while node != 0:
    join(values, reverse, 0, node)
    node = node div 2

proc weak_heapsort*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "weak_heapsort".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let count64 = input[0]
  if count64 < 0 or count64 > int64(MaxValues) or length != csize_t(count64 + 1): return -1
  let count = int(count64)
  var values: array[MaxValues, int64]
  var reverse: array[MaxValues, bool]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < -1000 or value > 1000: return -1
    values[index] = value

  var node = count - 1
  while node > 0:
    join(values, reverse, distinguishedAncestor(node, reverse), node)
    dec node

  var activeSize = count
  while activeSize > 1:
    swap(values[0], values[activeSize - 1])
    dec activeSize
    siftDown(values, reverse, activeSize)

  var checksum = 0'i64
  for index in 0 ..< count:
    checksum += int64(index + 1) * (values[index] + 1001)
  checksum
