const MaxOperations = 512
const MaxInsertions = 256

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (b * 8)) and 255)

proc max_heap*(input: ptr UncheckedArray[int64], length: csize_t,
               output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {. exportc, dynlib .} =
  if input == nil or length < 1: return -1
  let operations64 = input[0]
  if operations64 < 0 or operations64 > MaxOperations.int64: return -1
  let operations = int(operations64)
  if int(length) != 1 + operations * 2: return -1
  var inserts = 0
  var words = 0
  for i in 0 ..< operations:
    let op = input[1 + 2 * i]
    let value = input[2 + 2 * i]
    if op < 0 or op > 2: return -1
    if op == 0:
      inc inserts
      if inserts > MaxInsertions or value < low(int32).int64 or value > high(int32).int64: return -1
    else:
      if value != 0: return -1
      inc words
  if int(capacity) < words * 8 or (words > 0 and output == nil): return -2
  var heap: array[MaxInsertions, int64]
  var size = 0
  var out = 0
  for i in 0 ..< operations:
    let op = input[1 + 2 * i]
    let value = input[2 + 2 * i]
    if op == 0:
      var at = size
      heap[at] = value
      inc size
      while at > 0:
        let parent = (at - 1) div 2
        if heap[parent] >= heap[at]: break
        swap(heap[parent], heap[at])
        at = parent
      continue
    var result = int64.low
    if size > 0:
      result = heap[0]
      if op == 2:
        dec size
        heap[0] = heap[size]
        var at = 0
        while at < size div 2:
          var child = at * 2 + 1
          if child + 1 < size and heap[child + 1] > heap[child]: inc child
          if heap[at] >= heap[child]: break
          swap(heap[at], heap[child])
          at = child
    storeI64Le(output, out * 8, result)
    inc out
  int64(words)
