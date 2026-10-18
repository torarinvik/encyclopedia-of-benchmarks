const MaxOps = 64
const MaxInput = 130
const MaxOutput = 256

proc priority_queue*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "priority_queue".} =
  if input == nil or inputLength == 0 or inputLength > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxOps: return -1
  let opCount = int(input[0])
  var heap: array[MaxOps, int32]
  var seen: array[MaxOps, int32]
  var staged: array[MaxOutput, uint8]
  var heapSize = 0
  var seenCount = 0
  var offset = 1
  var outputSize = 0
  for k in 0 ..< opCount:
    if csize_t(offset) >= inputLength: return -1
    let op = input[offset]
    inc offset
    if op == 0:
      if csize_t(offset) >= inputLength: return -1
      let raw = input[offset]
      inc offset
      if raw < int64(low(int32)) or raw > int64(high(int32)): return -1
      let value = int32(raw)
      for j in 0 ..< seenCount:
        if seen[j] == value: return -1
      seen[seenCount] = value
      inc seenCount
      var i = heapSize
      inc heapSize
      heap[i] = value
      while i > 0:
        let parent = (i - 1) div 2
        if heap[parent] <= heap[i]: break
        swap(heap[parent], heap[i])
        i = parent
    elif op == 1 or op == 2:
      if heapSize == 0: return -1
      let bits = cast[uint32](heap[0])
      staged[outputSize] = uint8(bits and 0xff'u32); inc outputSize
      staged[outputSize] = uint8((bits shr 8) and 0xff'u32); inc outputSize
      staged[outputSize] = uint8((bits shr 16) and 0xff'u32); inc outputSize
      staged[outputSize] = uint8((bits shr 24) and 0xff'u32); inc outputSize
      if op == 2:
        dec heapSize
        heap[0] = heap[heapSize]
        var i = 0
        while i < heapSize:
          var child = 2 * i + 1
          if child >= heapSize: break
          if child + 1 < heapSize and heap[child + 1] < heap[child]: inc child
          if heap[i] <= heap[child]: break
          swap(heap[i], heap[child])
          i = child
    else:
      return -1
  if csize_t(offset) != inputLength: return -1
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
