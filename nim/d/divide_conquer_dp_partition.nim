const MaxN = 64
const MaxGroups = 8
const MaxInput = 66
const StackCapacity = 136
const Inf = high(int64) div 4

type Task = object
  left, right, low, high: int

proc computeRow(previous: openArray[int64], current: var openArray[int64],
                prefix: openArray[int64], n, group: int) =
  var stack: array[StackCapacity, Task]
  var top = 1
  stack[0] = Task(left: group, right: n, low: group - 1, high: n - 1)
  while top > 0:
    dec top
    let task = stack[top]
    if task.left > task.right: continue
    let middle = task.left + (task.right - task.left) div 2
    let upper = min(task.high, middle - 1)
    var best = Inf
    var bestSplit = task.low
    for split in task.low .. upper:
      if previous[split] == Inf: continue
      let segment = prefix[middle] - prefix[split]
      let candidate = previous[split] + segment * segment
      if candidate < best:
        best = candidate
        bestSplit = split
    current[middle] = best
    if middle < task.right:
      stack[top] = Task(left: middle + 1, right: task.right, low: bestSplit, high: task.high)
      inc top
    if task.left < middle:
      stack[top] = Task(left: task.left, right: middle - 1, low: task.low, high: bestSplit)
      inc top

proc divide_conquer_dp_partition*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "divide_conquer_dp_partition".} =
  if values.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let nValue = values[0]
  let groupsValue = values[1]
  if nValue < 1 or nValue > MaxN or groupsValue < 1 or groupsValue > MaxGroups or
     groupsValue > nValue or int(length) != int(nValue) + 2: return -1
  let n = int(nValue)
  let groups = int(groupsValue)
  var prefix: array[MaxN + 1, int64]
  var first: array[MaxN + 1, int64]
  var second: array[MaxN + 1, int64]
  for i in 0 ..< n:
    let value = values[i + 2]
    if value < 0 or value > 1000: return -1
    prefix[i + 1] = prefix[i] + value
  for i in 0 .. n: first[i] = Inf
  first[0] = 0
  var previous = first
  var current = second
  for group in 1 .. groups:
    for i in 0 .. n: current[i] = Inf
    computeRow(previous, current, prefix, n, group)
    swap(previous, current)
  previous[n]
