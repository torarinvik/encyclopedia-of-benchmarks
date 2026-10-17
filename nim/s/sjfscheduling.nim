const MaxInputLength = 130
const MaxProcesses = 64
const MaxOutputBytes = 256

type I32Input = ptr UncheckedArray[int32]

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc sjfscheduling*(input: I32Input, length: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "sjfscheduling".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let processCountValue = input[0]
  if processCountValue < 0 or processCountValue > MaxProcesses or
      length != csize_t(1 + 2 * processCountValue): return -1
  let processCount = int(processCountValue)

  var arrivals: array[MaxProcesses, int32]
  var bursts: array[MaxProcesses, int32]
  var order: array[MaxProcesses, int32]
  var completed: array[MaxProcesses, bool]
  var cursor = 1
  for index in 0 ..< processCount:
    let arrival = input[cursor]
    let burst = input[cursor + 1]
    cursor += 2
    if arrival < 0 or arrival > 255 or burst < 1 or burst > 255: return -1
    arrivals[index] = arrival
    bursts[index] = burst

  var currentTime = 0'i32
  var scheduled = 0
  while scheduled < processCount:
    var best = processCount
    for index in 0 ..< processCount:
      if completed[index] or arrivals[index] > currentTime: continue
      if best == processCount or bursts[index] < bursts[best] or
          (bursts[index] == bursts[best] and
           (arrivals[index] < arrivals[best] or
            (arrivals[index] == arrivals[best] and index < best))):
        best = index
    if best == processCount:
      inc currentTime
    else:
      order[scheduled] = int32(best)
      inc scheduled
      completed[best] = true
      currentTime += bursts[best]

  let outputBytes = processCount * 4
  if output == nil or outputCapacity < csize_t(outputBytes) or outputBytes > MaxOutputBytes:
    return -2
  for index in 0 ..< processCount:
    writeI32Le(output, index * 4, order[index])
  int64(outputBytes)
