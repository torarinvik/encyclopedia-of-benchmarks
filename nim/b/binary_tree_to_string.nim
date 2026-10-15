const MaxNodes = 127

proc decimalLength(value: int64): int =
  var magnitude = if value < 0: -value else: value
  result = if value < 0: 1 else: 0
  while magnitude >= 10:
    magnitude = magnitude div 10
    inc result
  inc result

proc appendValue(value: int32, output: ptr UncheckedArray[uint8], position: var int) =
  var magnitude = if value < 0: int64(-value) else: int64(value)
  var digits: array[10, uint8]
  var count = 0
  if value < 0:
    output[position] = uint8(ord('-')); inc position
  while true:
    digits[count] = uint8(ord('0') + int(magnitude mod 10))
    inc count
    magnitude = magnitude div 10
    if magnitude == 0: break
  while count > 0:
    dec count
    output[position] = digits[count]
    inc position

proc emitNode(values: ptr UncheckedArray[int64], index: int,
    output: ptr UncheckedArray[uint8], position: var int) =
  let base = 2 + 3 * index
  let left = values[base + 1]
  let right = values[base + 2]
  appendValue(int32(values[base]), output, position)
  if left >= 0:
    output[position] = uint8(ord('(')); inc position
    emitNode(values, int(left), output, position)
    output[position] = uint8(ord(')')); inc position
  elif right >= 0:
    output[position] = uint8(ord('(')); inc position
    output[position] = uint8(ord(')')); inc position
  if right >= 0:
    output[position] = uint8(ord('(')); inc position
    emitNode(values, int(right), output, position)
    output[position] = uint8(ord(')')); inc position

proc binary_tree_to_string*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_tree_to_string".} =
  if values == nil or length < 2: return -1
  if values[0] < 0 or values[0] > int64(MaxNodes): return -1
  let count = int(values[0])
  if length != csize_t(2 + 3 * count): return -1
  let rootValue = values[1]
  if count == 0: return (if rootValue == -1: 0 else: -1)
  if rootValue < 0 or rootValue >= int64(count): return -1
  var parents: array[MaxNodes, uint8]
  var seen: array[MaxNodes, bool]
  var stack: array[MaxNodes, int]
  for i in 0 ..< count:
    let base = 2 + 3 * i
    let value = values[base]
    let left = values[base + 1]
    let right = values[base + 2]
    if value < -2147483648'i64 or value > 2147483647'i64 or left < -1 or right < -1 or
        (left >= 0 and left >= int64(count)) or (right >= 0 and right >= int64(count)): return -1
    if left >= 0:
      inc parents[int(left)]
      if parents[int(left)] > 1: return -1
    if right >= 0:
      inc parents[int(right)]
      if parents[int(right)] > 1: return -1
  let root = int(rootValue)
  for i in 0 ..< count:
    if parents[i] != (if i == root: 0'u8 else: 1'u8): return -1
  var top = 1
  var visited = 0
  stack[0] = root
  while top > 0:
    dec top
    let index = stack[top]
    if seen[index]: return -1
    seen[index] = true
    inc visited
    let base = 2 + 3 * index
    let left = values[base + 1]
    let right = values[base + 2]
    if left >= 0:
      stack[top] = int(left); inc top
    if right >= 0:
      stack[top] = int(right); inc top
  if visited != count: return -1
  var required = 2 * (count - 1)
  for i in 0 ..< count:
    let base = 2 + 3 * i
    required += decimalLength(values[base])
    if values[base + 1] == -1 and values[base + 2] >= 0: required += 2
  if output == nil or outputCapacity < csize_t(required): return -2
  var position = 0
  emitNode(values, root, output, position)
  int64(position)
