const MaxAppendCount = 4096'i64
const MaxTextBytes = 24576

proc shootout_strcat*(appendCount: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_strcat".} =
  if appendCount < 0 or appendCount > MaxAppendCount: return -1

  var text: array[MaxTextBytes + 1, uint8]
  var length = 0
  var bufferCapacity = 32
  for _ in 0 ..< int(appendCount):
    if bufferCapacity - length < 7: bufferCapacity *= 2
    text[length] = 104'u8
    text[length + 1] = 101'u8
    text[length + 2] = 108'u8
    text[length + 3] = 108'u8
    text[length + 4] = 111'u8
    text[length + 5] = 10'u8
    length += 6
    text[length] = 0'u8

  var staged: array[6, uint8]
  var reversedDigits: array[5, uint8]
  var digitCount = 0
  var value = length
  while true:
    reversedDigits[digitCount] = uint8(48 + value mod 10)
    inc digitCount
    value = value div 10
    if value == 0: break
  var used = 0
  while digitCount > 0:
    dec digitCount
    staged[used] = reversedDigits[digitCount]
    inc used
  staged[used] = 10'u8
  inc used

  if output.isNil or outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
