const
  MaxBlockCount = 16
  MaxProcessCount = 32
  MaxInputLength = 52
  MaxOutputBytes = 256
  NoAllocation = -255'i64

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc memoryManagementAlgorithms*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "memory_management_algorithms".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength.csize_t: return -1
  let policy = input[0]
  if policy < 0 or policy > 3 or input[1] < 1 or input[1] > MaxBlockCount.int64 or
      input[2] < 0 or input[2] > MaxProcessCount.int64: return -1
  let blockCount = int(input[1])
  let processCount = int(input[2])
  if inputLength != csize_t(3 + blockCount + processCount): return -1

  var blocks: array[MaxBlockCount, int64]
  var processes: array[MaxProcessCount, int64]
  for index in 0 ..< blockCount:
    let size = input[3 + index]
    if size < 1 or size > 10000: return -1
    blocks[index] = size
  for index in 0 ..< processCount:
    let size = input[3 + blockCount + index]
    if size < 1 or size > 10000: return -1
    processes[index] = size

  var allocations: array[MaxProcessCount, int64]
  var nextFitCounter = 0
  for processIndex in 0 ..< processCount:
    let process = processes[processIndex]
    var selected = NoAllocation
    if policy == 0:
      for index in 0 ..< blockCount:
        if blocks[index] >= process:
          selected = int64(index)
          break
    elif policy == 1:
      var minDiff = blocks[0]
      for index in 1 ..< blockCount:
        if blocks[index] > minDiff: minDiff = blocks[index]
      for index in 0 ..< blockCount:
        let difference = blocks[index] - process
        if difference < minDiff and difference >= 0:
          minDiff = difference
          selected = int64(index)
    elif policy == 2:
      var best = 0
      for candidate in 1 ..< blockCount:
        if blocks[candidate] > blocks[best]: best = candidate
      if blocks[best] >= process: selected = int64(best)
    else:
      var found = false
      for offset in 0 ..< blockCount:
        if nextFitCounter + offset >= blockCount: nextFitCounter = -offset
        let index = offset + nextFitCounter
        if blocks[index] >= process:
          nextFitCounter += offset
          selected = int64(nextFitCounter)
          found = true
          break
      if not found: nextFitCounter += blockCount
    allocations[processIndex] = selected
    if selected != NoAllocation: blocks[int(selected)] -= process

  let outputBytes = processCount * 8
  if outputBytes > MaxOutputBytes: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< processCount: putI64Le(output, index * 8, allocations[index])
  int64(outputBytes)
