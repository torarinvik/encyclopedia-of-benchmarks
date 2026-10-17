const MaxQueues = 4
const MaxProcesses = 8
const MaxInputWords = 13
const MaxOutputWords = 1 + 4 * MaxProcesses
const MaxOutputBytes = 4 * MaxOutputWords

type
  Process = object
    id, remaining, waiting, turnaround, stopTime: int32
  I32Input = ptr UncheckedArray[int32]
  U8Output = ptr UncheckedArray[uint8]

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc multi_level_feedback_queue*(input: I32Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "multi_level_feedback_queue".} =
  if input == nil or length < 2 or length > csize_t(MaxInputWords): return -1
  let queueCountRaw = input[0]
  let processCountRaw = input[1]
  if queueCountRaw < 1 or queueCountRaw > MaxQueues or processCountRaw < 0 or processCountRaw > MaxProcesses: return -1
  let queueCount = int(queueCountRaw)
  let processCount = int(processCountRaw)
  if int(length) != 2 + queueCount - 1 + processCount: return -1

  var slices: array[MaxQueues - 1, int32]
  var pos = 2
  for i in 0 ..< queueCount - 1:
    if input[pos] < 1 or input[pos] > 16: return -1
    slices[i] = input[pos]
    inc pos
  var ready: array[MaxProcesses, Process]
  var readyCount = processCount
  for i in 0 ..< processCount:
    let burst = input[pos]
    inc pos
    if burst < 1 or burst > 16: return -1
    ready[i] = Process(id: int32(i), remaining: burst, waiting: 0, turnaround: 0, stopTime: 0)

  var finished: array[MaxProcesses, Process]
  var finishedCount = 0
  var currentTime = 0'i32
  for level in 0 ..< queueCount - 1:
    var nextReady: array[MaxProcesses, Process]
    var nextCount = 0
    let timeSlice = slices[level]
    for i in 0 ..< readyCount:
      var process = ready[i]
      process.waiting += currentTime - process.stopTime
      if process.remaining > timeSlice:
        currentTime += timeSlice
        process.remaining -= timeSlice
        process.stopTime = currentTime
        nextReady[nextCount] = process
        inc nextCount
      else:
        currentTime += process.remaining
        process.remaining = 0
        process.stopTime = currentTime
        process.turnaround = currentTime
        finished[finishedCount] = process
        inc finishedCount
    ready = nextReady
    readyCount = nextCount

  for i in 0 ..< readyCount:
    var process = ready[i]
    process.waiting += currentTime - process.stopTime
    currentTime += process.remaining
    process.remaining = 0
    process.stopTime = currentTime
    process.turnaround = currentTime
    finished[finishedCount] = process
    inc finishedCount

  if finishedCount != processCount: return -1
  var words: array[MaxOutputWords, int32]
  var wordCount = 1
  words[0] = int32(processCount)
  for i in 0 ..< finishedCount:
    words[wordCount] = finished[i].id
    words[wordCount + 1] = finished[i].waiting
    words[wordCount + 2] = finished[i].turnaround
    words[wordCount + 3] = finished[i].stopTime
    wordCount += 4
  let bytes = wordCount * 4
  if output == nil or capacity < csize_t(bytes): return -2
  var buffer: array[MaxOutputBytes, uint8]
  for i in 0 ..< wordCount:
    putI32Le(cast[U8Output](addr buffer[0]), i * 4, words[i])
  for i in 0 ..< bytes: output[i] = buffer[i]
  int64(bytes)
