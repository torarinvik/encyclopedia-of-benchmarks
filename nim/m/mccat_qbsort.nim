const MaxItems = 32
proc bubble(a: var array[MaxItems, int32], n: int) =
  if n < 2: return
  for endIndex in countdown(n - 1, 1):
    for i in 0 ..< endIndex:
      if a[i + 1] < a[i]: swap(a[i], a[i + 1])
type Node = ref object
  value: int32
  next: Node

proc quick(items: Node): Node =
  if items.isNil: return nil
  let pivot = items.value
  var lower, upper: Node
  var current = items.next
  while not current.isNil:
    if current.value < pivot:
      lower = Node(value: current.value, next: lower)
    else:
      upper = Node(value: current.value, next: upper)
    current = current.next
  let sortedUpper = quick(upper)
  let sortedLower = quick(lower)
  let pivotNode = Node(value: pivot, next: sortedUpper)
  if sortedLower.isNil: return pivotNode
  var tail = sortedLower
  while not tail.next.isNil: tail = tail.next
  tail.next = pivotNode
  sortedLower
proc putLe(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  var bits = cast[uint32](value)
  for b in 0 ..< 4:
    output[index * 4 + b] = uint8(bits and 255)
    bits = bits shr 8
proc mccat_qbsort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mccat_qbsort".} =
  if input == nil or length < 3 or length > 34: return -1
  let mode = input[0]
  let countValue = input[1]
  if (mode != 0 and mode != 1) or countValue < 1 or countValue > MaxItems: return -1
  let n = int(countValue)
  if length != csize_t(n + 2): return -1
  var values: array[MaxItems, int32]
  for i in 0 ..< n:
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
    values[i] = int32(input[i + 2])
  for pass in 0 ..< 1000:
    for i in 0 ..< n: values[i] = int32(input[i + 2])
    if mode == 0:
      bubble(values, n)
    else:
      var items: Node
      for i in countdown(n - 1, 0): items = Node(value: values[i], next: items)
      var sorted = quick(items)
      var i = 0
      while not sorted.isNil:
        values[i] = sorted.value
        inc i
        sorted = sorted.next
  let required = n * 4
  if output == nil or outputCapacity < csize_t(required): return -2
  for i in 0 ..< n: putLe(output, i, values[i])
  int64(required)
