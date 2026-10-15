const RequiredBytes = [0, 2, 8, 30, 112, 420, 1584]

proc walk(pairs, opened, closed: int, buffer: var array[12, uint8],
    output: var seq[uint8], cursor: int): int =
  let position = opened + closed
  if position == 2 * pairs:
    var next = cursor
    for index in 0 ..< position:
      output[next] = buffer[index]
      inc next
    return next
  var next = cursor
  if opened < pairs:
    buffer[position] = uint8(ord('('))
    next = walk(pairs, opened + 1, closed, buffer, output, next)
  if closed < opened:
    buffer[position] = uint8(ord(')'))
    next = walk(pairs, opened, closed + 1, buffer, output, next)
  next

proc generate_parentheses*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "generate_parentheses".} =
  if input.isNil or length != 1 or input[0] < 1 or input[0] > 6: return -1
  let pairs = int(input[0])
  let required = RequiredBytes[pairs]
  if int(capacity) < required or output.isNil: return -2
  var buffer: array[12, uint8]
  var bytes = newSeq[uint8](required)
  discard walk(pairs, 0, 0, buffer, bytes, 0)
  for index in 0 ..< required:
    output[index] = bytes[index]
  int64(required)
