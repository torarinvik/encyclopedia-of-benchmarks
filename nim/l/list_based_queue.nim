const MaxOps = 32

proc listBasedQueue*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "list_based_queue".} =
  if input == nil or length < 1 or length > 66: return -1
  if input[0] < 0 or input[0] > MaxOps: return -1
  let opCount = int(input[0])
  var nodeValues: array[MaxOps, int32]
  var nextNode: array[MaxOps, int32]
  var words: array[64, int64]
  var allocated = 0
  var wordCount = 0
  var pos = 1
  var size = 0
  var head = -1
  var tail = -1
  for _ in 0 ..< opCount:
    if pos >= int(length): return -1
    let opcode = input[pos]
    inc pos
    if opcode == 0:
      if pos >= int(length): return -1
      let value = input[pos]
      inc pos
      if value < int64(low(int32)) or value > int64(high(int32)) or allocated >= MaxOps: return -1
      nodeValues[allocated] = int32(value)
      nextNode[allocated] = -1
      if tail < 0: head = allocated
      else: nextNode[tail] = allocated
      tail = allocated
      inc allocated
      inc size
      words[wordCount] = 0; words[wordCount + 1] = 1; wordCount += 2
    elif opcode == 1:
      if head < 0: return -1
      let node = head
      head = int(nextNode[node])
      if head < 0: tail = -1
      dec size
      words[wordCount] = 1; words[wordCount + 1] = int64(nodeValues[node]); wordCount += 2
    elif opcode == 2:
      if head < 0: return -1
      words[wordCount] = 2; words[wordCount + 1] = int64(nodeValues[head]); wordCount += 2
    elif opcode == 3:
      head = -1; tail = -1; size = 0
      words[wordCount] = 3; words[wordCount + 1] = 1; wordCount += 2
    elif opcode == 4:
      words[wordCount] = 4; words[wordCount + 1] = (if size == 0: 1 else: 0); wordCount += 2
    elif opcode == 5:
      words[wordCount] = 5; words[wordCount + 1] = 0; wordCount += 2
    else:
      return -1
  if pos != int(length) or int(length) > 1 + 2 * opCount or wordCount > 64: return -1
  let bytes = wordCount * 8
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for i in 0 ..< wordCount:
    let bits = cast[uint64](words[i])
    for b in 0 ..< 8:
      output[8 * i + b] = uint8((bits shr (8 * b)) and 255)
  int64(bytes)
