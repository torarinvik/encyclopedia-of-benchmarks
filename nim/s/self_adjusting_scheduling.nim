const MaxTasks = 16
const MaxSteps = 64
const MaxInputLength = MaxTasks + 3

proc self_adjusting_scheduling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "self_adjusting_scheduling".} =
  if input.isNil or length < 3 or length > MaxInputLength: return -1
  let taskCountValue = input[0]
  let stepsValue = input[1]
  if taskCountValue < 1 or taskCountValue > MaxTasks or stepsValue < 0 or stepsValue > MaxSteps: return -1
  let taskCount = int(taskCountValue)
  let steps = int(stepsValue)
  if int(length) != taskCount + 2: return -1

  var priorities: array[MaxTasks, int64]
  var waitTimes: array[MaxTasks, int64]
  var schedule: array[MaxSteps, uint8]
  for task in 0 ..< taskCount:
    let priority = input[task + 2]
    if priority < low(int32).int64 or priority > high(int32).int64: return -1
    priorities[task] = priority

  for step in 0 ..< steps:
    for left in 0 ..< taskCount:
      for right in left + 1 ..< taskCount:
        if priorities[left] == priorities[right]: return -1
    var selected = 0
    for task in 1 ..< taskCount:
      if priorities[task] < priorities[selected]: selected = task
    schedule[step] = uint8(selected)
    inc waitTimes[selected]
    let updatedPriority = priorities[selected] + waitTimes[selected]
    if updatedPriority < low(int32).int64 or updatedPriority > high(int32).int64: return -1
    priorities[selected] = updatedPriority

  if output.isNil or capacity < csize_t(steps): return -2
  for step in 0 ..< steps: output[step] = schedule[step]
  int64(steps)
