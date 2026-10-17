const MaxJobs = 64
const MaxOutput = 4 + 12 * MaxJobs
const I32Max = 2147483647'i64

type Job = object
  processing: int32
  deadline: int32
  originalIndex: int32
  startTime: int32
  lateness: int32

proc writeI32(output: var array[MaxOutput, uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u32)

proc minimizing_lateness*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "minimizing_lateness".} =
  if input.isNil or length < 1 or length > csize_t(1 + 2 * MaxJobs): return -1
  let countValue = input[0]
  if countValue < 0 or countValue > int64(MaxJobs) or length != csize_t(1 + 2 * countValue): return -1
  let count = int(countValue)
  var jobs: array[MaxJobs, Job]
  var totalProcessing = 0'i64
  for i in 0 ..< count:
    let processing = input[1 + 2 * i]
    let deadline = input[2 + 2 * i]
    if processing < 0 or processing > I32Max or deadline < 0 or deadline > I32Max: return -1
    totalProcessing += processing
    if totalProcessing > I32Max: return -1
    jobs[i] = Job(processing: int32(processing), deadline: int32(deadline), originalIndex: int32(i))

  # Stable insertion sort retains original order when deadlines are equal.
  var i = 1
  while i < count:
    let item = jobs[i]
    var position = i
    while position > 0 and jobs[position - 1].deadline > item.deadline:
      jobs[position] = jobs[position - 1]
      dec position
    jobs[position] = item
    inc i

  var startTime = 0'i64
  for i in 0 ..< count:
    jobs[i].startTime = int32(startTime)
    let finishTime = startTime + int64(jobs[i].processing)
    jobs[i].lateness = int32(max(0'i64, finishTime - int64(jobs[i].deadline)))
    startTime = finishTime

  let needed = 4 + 12 * count
  if output.isNil or outputCapacity < csize_t(needed): return -2
  var payload: array[MaxOutput, uint8]
  writeI32(payload, 0, int32(count))
  for i in 0 ..< count:
    let offset = 4 + 12 * i
    writeI32(payload, offset, jobs[i].originalIndex)
    writeI32(payload, offset + 4, jobs[i].startTime)
    writeI32(payload, offset + 8, jobs[i].lateness)
  copyMem(output, addr payload[0], needed)
  int64(needed)
