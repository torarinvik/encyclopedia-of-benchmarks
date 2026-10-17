const MaxOps = 64
const MaxInputLength = 129
const MaxOutputWords = 1 + 2 * MaxOps
const MaxOutputBytes = 4 * MaxOutputWords

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc randomized_heap*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "randomized_heap".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxOps: return -1
  let operationCount = int(input[0])
  var heap: array[MaxOps, int32]
  var words: array[MaxOutputWords, int32]
  var heapSize = 0
  var wordCount = 1
  var queryCount = 0
  var pos = 1

  for _ in 0 ..< operationCount:
    if pos >= int(length): return -1
    let opcode = input[pos]
    inc pos
    if opcode == 0:
      if pos >= int(length): return -1
      let raw = input[pos]
      inc pos
      if raw < int64(low(int32)) or raw > int64(high(int32)): return -1
      var index = heapSize
      heap[index] = int32(raw)
      while index > 0:
        let parent = (index - 1) div 2
        if heap[parent] <= heap[index]: break
        swap(heap[parent], heap[index])
        index = parent
      inc heapSize
    elif opcode == 1 or opcode == 2:
      if heapSize == 0: return -1
      let value = heap[0]
      if opcode == 2:
        dec heapSize
        if heapSize > 0:
          heap[0] = heap[heapSize]
          var index = 0
          while true:
            let left = 2 * index + 1
            if left >= heapSize: break
            let right = left + 1
            var child = left
            if right < heapSize and heap[right] < heap[left]: child = right
            if heap[index] <= heap[child]: break
            swap(heap[index], heap[child])
            index = child
      words[wordCount] = if opcode == 1: 1'i32 else: 2'i32
      words[wordCount + 1] = value
      wordCount += 2
      inc queryCount
    elif opcode == 3:
      words[wordCount] = 3
      words[wordCount + 1] = if heapSize == 0: 1'i32 else: 0'i32
      wordCount += 2
      inc queryCount
    else:
      return -1

  if pos != int(length) or wordCount > MaxOutputWords: return -1
  words[0] = int32(queryCount)
  let bytes = wordCount * 4
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  for i in 0 ..< wordCount:
    putI32Le(cast[U8Output](addr buffer[0]), i * 4, words[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
