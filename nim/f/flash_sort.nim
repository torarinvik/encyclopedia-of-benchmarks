## Bounded Flash Sort followed by the source's insertion-sort finishing pass.
const MaxLength = 64

proc validLength(length: int): bool = length <= 1 or (length >= 3 and length <= MaxLength)

proc classOf(value, minimum, range: int64, classes: int): int =
  int((int64(classes - 1) * (value - minimum)) div range)

proc flashSortValues(values: var array[MaxLength, int64], length: int): bool =
  if length <= 1: return true
  var minimum = values[0]
  var maximum = values[0]
  for index in 1 ..< length:
    if values[index] < minimum: minimum = values[index]
    if values[index] > maximum: maximum = values[index]
  if minimum == maximum: return true
  let range = maximum - minimum
  var classes = (9 * length) div 20
  if classes < 1: classes = 1
  var classEnds: array[MaxLength, int]
  for index in 0 ..< length:
    inc classEnds[classOf(values[index], minimum, range, classes)]
  for index in 1 ..< classes:
    classEnds[index] += classEnds[index - 1]
  var moves = 0
  var j = 0
  var k = classes - 1
  while moves < length - 1:
    while j > classEnds[k] - 1:
      inc j
      if j >= length: return false
      k = classOf(values[j], minimum, range, classes)
    var flash = values[j]
    while j != classEnds[k]:
      k = classOf(flash, minimum, range, classes)
      dec classEnds[k]
      let target = classEnds[k]
      let hold = values[target]
      values[target] = flash
      flash = hold
      inc moves
  for index in 1 ..< length:
    let key = values[index]
    var cursor = index
    while cursor > 0 and values[cursor - 1] > key:
      values[cursor] = values[cursor - 1]
      dec cursor
    values[cursor] = key
  true

proc flashSort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "flash_sort".} =
  if length > csize_t(65): return -1
  let n = int(length)
  if not validLength(n) or (n != 0 and input == nil): return -1
  var values: array[MaxLength, int64]
  for index in 0 ..< n:
    if input[index] < -1_000_000 or input[index] > 1_000_000: return -1
    values[index] = input[index]
  let outputBytes = n * 4
  if outputCapacity < csize_t(outputBytes) or (outputBytes != 0 and output == nil): return -2
  if not flashSortValues(values, n): return -1
  for index in 0 ..< n:
    let bits = cast[uint32](int32(values[index]))
    for byte in 0 ..< 4: output[index * 4 + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(outputBytes)
