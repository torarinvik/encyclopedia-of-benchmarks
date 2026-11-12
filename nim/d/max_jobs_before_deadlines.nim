const MaxJobs = 12

proc before(leftDuration: int64, leftId: int, rightDuration: int64, rightId: int): bool =
  leftDuration < rightDuration or (leftDuration == rightDuration and leftId < rightId)

proc heapPush(durations: var array[MaxJobs, int64], ids: var array[MaxJobs, int],
    size: var int, duration: int64, id: int) =
  var index = size
  inc size
  while index > 0:
    let parent = (index - 1) div 2
    if not before(duration, id, durations[parent], ids[parent]): break
    durations[index] = durations[parent]
    ids[index] = ids[parent]
    index = parent
  durations[index] = duration
  ids[index] = id

proc heapPop(durations: var array[MaxJobs, int64], ids: var array[MaxJobs, int],
    size: var int): tuple[duration: int64, id: int] =
  result = (durations[0], ids[0])
  dec size
  if size == 0: return
  let lastDuration = durations[size]
  let lastId = ids[size]
  var index = 0
  while 2 * index + 1 < size:
    var child = 2 * index + 1
    if child + 1 < size and before(durations[child + 1], ids[child + 1], durations[child], ids[child]):
      inc child
    if not before(durations[child], ids[child], lastDuration, lastId): break
    durations[index] = durations[child]
    ids[index] = ids[child]
    index = child
  durations[index] = lastDuration
  ids[index] = lastId

proc max_jobs_before_deadlines*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "max_jobs_before_deadlines".} =
  if input.isNil or length < 1 or length > 25: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxJobs or int(length) != 1 + 2 * int(countValue): return -1
  let count = int(countValue)
  var deadlines: array[MaxJobs, int64]
  var durations: array[MaxJobs, int64]
  var ids: array[MaxJobs, int]
  for i in 0 ..< count:
    let deadline = input[1 + 2 * i]
    let duration = input[2 + 2 * i]
    if deadline < 0 or deadline > 1000 or duration < 1 or duration > 1000: return -1
    deadlines[i] = deadline
    durations[i] = duration
    ids[i] = i
  for i in 1 ..< count:
    let deadline = deadlines[i]
    let duration = durations[i]
    let id = ids[i]
    var position = i
    while position > 0 and deadlines[position - 1] > deadline:
      deadlines[position] = deadlines[position - 1]
      durations[position] = durations[position - 1]
      ids[position] = ids[position - 1]
      dec position
    deadlines[position] = deadline
    durations[position] = duration
    ids[position] = id
  var heapDurations: array[MaxJobs, int64]
  var heapIds: array[MaxJobs, int]
  var heapSize = 0
  var completed = 0'i64
  var end = count
  while end > 0:
    dec end
    heapPush(heapDurations, heapIds, heapSize, durations[end], ids[end])
    let lower = if end == 0: 0'i64 else: deadlines[end - 1]
    var interval = deadlines[end] - lower
    while interval > 0 and heapSize > 0:
      let item = heapPop(heapDurations, heapIds, heapSize)
      if item.duration <= interval:
        interval -= item.duration
        inc completed
      else:
        heapPush(heapDurations, heapIds, heapSize, item.duration - interval, item.id)
        interval = 0
  completed
