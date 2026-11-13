const MaxMachines = 8
const MaxTasks = 32
const MaxParseableWords = 99

proc eventLess(left, right: int; finish: openArray[int64]): bool =
  finish[left] < finish[right] or (finish[left] == finish[right] and left < right)

proc heapPush(heap: var array[MaxTasks, int]; size: var int; task: int,
              finish: openArray[int64]) =
  var position = size
  inc size
  while position > 0:
    let parent = (position - 1) div 2
    if not eventLess(task, heap[parent], finish): break
    heap[position] = heap[parent]
    position = parent
  heap[position] = task

proc heapPop(heap: var array[MaxTasks, int]; size: var int,
             finish: openArray[int64]): int =
  result = heap[0]
  dec size
  if size == 0: return
  let replacement = heap[size]
  var position = 0
  while true:
    let left = 2 * position + 1
    if left >= size: break
    let right = left + 1
    var child = left
    if right < size and eventLess(heap[right], heap[left], finish): child = right
    if not eventLess(heap[child], replacement, finish): break
    heap[position] = heap[child]
    position = child
  heap[position] = replacement

proc online_temporary_task_load_balancing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "online_temporary_task_load_balancing".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableWords): return -1
  if input[0] < 1 or input[0] > int64(MaxMachines) or input[1] < 0 or input[1] > int64(MaxTasks): return -1
  let machineCount = int(input[0])
  let taskCount = int(input[1])
  if length != csize_t(2 + 3 * taskCount): return -1

  var arrivals: array[MaxTasks, int64]
  var weights: array[MaxTasks, int64]
  var finish: array[MaxTasks, int64]
  var assigned: array[MaxTasks, int]
  var loads: array[MaxMachines, int64]
  var heap: array[MaxTasks, int]
  var heapSize = 0
  var staged: array[MaxTasks + 1, int64]
  var previousArrival = -1'i64
  for task in 0 ..< taskCount:
    let at = input[2 + 3 * task]
    let amount = input[3 + 3 * task]
    let duration = input[4 + 3 * task]
    if at < 0 or at > 1000 or at < previousArrival or amount < 1 or amount > 1000 or
       duration < 1 or duration > 1000 or at + duration > 2000: return -1
    arrivals[task] = at
    weights[task] = amount
    finish[task] = at + duration
    previousArrival = at

  var peak = 0'i64
  for task in 0 ..< taskCount:
    while heapSize > 0 and finish[heap[0]] <= arrivals[task]:
      let expired = heapPop(heap, heapSize, finish)
      loads[assigned[expired]] -= weights[expired]
    var machine = 0
    for candidate in 1 ..< machineCount:
      if loads[candidate] < loads[machine]: machine = candidate
    assigned[task] = machine
    loads[machine] += weights[task]
    if loads[machine] > peak: peak = loads[machine]
    heapPush(heap, heapSize, task, finish)

  staged[0] = peak
  for task in 0 ..< taskCount: staged[task + 1] = int64(assigned[task])
  let outputWords = taskCount + 1
  let outputBytes = 8 * outputWords
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for word in 0 ..< outputWords:
    let bits = uint64(staged[word])
    for byte in 0 ..< 8: output[8 * word + byte] = uint8((bits shr (8 * byte)) and 255'u64)
  int64(outputBytes)
