const MaxQueueSize = 10
const MaxOps = 64
const MaxInputLength = 129
const MaxOutputWords = 130
const MaxOutputBytes = 4 * MaxOutputWords

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc list_queue*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "list_queue".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxOps: return -1
  let opCount = int(input[0])
  var queue: array[MaxQueueSize, int32]
  var words: array[MaxOutputWords, int32]
  var wordCount = 1
  var queryCount = 0
  var pos = 1
  var queueSize = 0
  for _ in 0 ..< opCount:
    if pos >= int(length): return -1
    let opcode = input[pos]
    inc pos
    if opcode == 0:
      if pos >= int(length): return -1
      let raw = input[pos]
      inc pos
      if raw < int64(low(int32)) or raw > int64(high(int32)) or queueSize >= MaxQueueSize: return -1
      queue[queueSize] = int32(raw)
      inc queueSize
    elif opcode == 1:
      if queueSize == 0:
        words[wordCount] = 3
        words[wordCount + 1] = 0
      else:
        let value = queue[0]
        for i in 0 ..< MaxQueueSize - 1: queue[i] = queue[i + 1]
        dec queueSize
        words[wordCount] = 1
        words[wordCount + 1] = value
      wordCount += 2
      inc queryCount
    elif opcode == 2:
      words[wordCount] = 2
      words[wordCount + 1] = int32(queueSize)
      wordCount += 2
      inc queryCount
    else:
      return -1
  if pos != int(length) or wordCount + 1 + queueSize > MaxOutputWords: return -1
  words[0] = int32(queryCount)
  words[wordCount] = int32(queueSize)
  inc wordCount
  for i in 0 ..< queueSize:
    words[wordCount] = queue[i]
    inc wordCount
  let bytes = wordCount * 4
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  for i in 0 ..< wordCount:
    putI32Le(cast[U8Output](addr buffer[0]), i * 4, words[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
