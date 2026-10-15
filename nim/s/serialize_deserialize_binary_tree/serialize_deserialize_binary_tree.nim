const MaxInput = 2200
const MaxNodes = 127

proc asciiSpace(value: int64): bool =
  value == 32 or (value >= 9 and value <= 13)

proc parseInteger(input: ptr UncheckedArray[int64], firstArg, lastArg: int,
                  number: var int32): bool =
  var first = firstArg
  var last = lastArg
  while first < last and asciiSpace(input[first]): inc first
  while last > first and asciiSpace(input[last - 1]): dec last
  if first == last: return false
  var negative = false
  if input[first] == 45 or input[first] == 43:
    negative = input[first] == 45
    inc first
  if first == last: return false
  let limit = if negative: 2_147_483_648'i64 else: 2_147_483_647'i64
  var magnitude = 0'i64
  for i in first ..< last:
    if input[i] < 48 or input[i] > 57: return false
    let digit = input[i] - 48
    if magnitude > (limit - digit) div 10: return false
    magnitude = magnitude * 10 + digit
  number = int32(if negative: -magnitude else: magnitude)
  true

proc serialize_deserialize_binary_tree*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "serialize_deserialize_binary_tree".} =
  if values.isNil or length == 0 or length > MaxInput.csize_t: return -1
  let count = int(length)
  for i in 0 ..< count:
    if values[i] < 0 or values[i] > 127: return -1
  var encoded = newStringOfCap(count)
  var position = 0
  var slots = 1
  var nodes = 0
  while position < count:
    if slots == 0: return -1
    let start = position
    while position < count and values[position] != 44: inc position
    let finish = position
    if start == finish: return -1
    let isNull = finish - start == 4 and values[start] == 110 and values[start + 1] == 117 and
                 values[start + 2] == 108 and values[start + 3] == 108
    if encoded.len > 0: encoded.add(',')
    if isNull:
      encoded.add("null")
    else:
      var number: int32
      if not parseInteger(values, start, finish, number): return -1
      inc nodes
      if nodes > MaxNodes: return -1
      encoded.add($number)
    dec slots
    if not isNull: slots += 2
    if position < count:
      inc position
      if position == count: return -1
  if slots != 0: return -1
  if output.isNil or outputCapacity < encoded.len.csize_t: return -2
  for i in 0 ..< encoded.len: output[i] = uint8(ord(encoded[i]))
  int64(encoded.len)
