const MaxProcesses = 16
const MaxResources = 8

## Check whether the process/resource state has a safe completion order.
proc bankers_algorithm*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "bankers_algorithm".} =
  if values == nil or length < 5 or length > 266: return -1
  let processValue = values[0]
  let resourceValue = values[1]
  if processValue < 1 or processValue > MaxProcesses or resourceValue < 1 or resourceValue > MaxResources: return -1
  let processes = int(processValue)
  let resources = int(resourceValue)
  let maximumOffset = 2 + resources
  let allocationOffset = maximumOffset + processes * resources
  if length != csize_t(allocationOffset + processes * resources): return -1
  var work: array[MaxResources, int64]
  for resource in 0 ..< resources:
    let available = values[2 + resource]
    if available < 0 or available > 100: return -1
    work[resource] = available
  for process in 0 ..< processes:
    for resource in 0 ..< resources:
      let index = process * resources + resource
      let maximum = values[maximumOffset + index]
      let allocation = values[allocationOffset + index]
      if maximum < 0 or maximum > 100 or allocation < 0 or allocation > maximum: return -1
  var finished: array[MaxProcesses, bool]
  var completed = 0
  while completed < processes:
    var progress = false
    for process in 0 ..< processes:
      if finished[process]: continue
      var feasible = true
      for resource in 0 ..< resources:
        let index = process * resources + resource
        let need = values[maximumOffset + index] - values[allocationOffset + index]
        if need > work[resource]:
          feasible = false
          break
      if feasible:
        for resource in 0 ..< resources:
          work[resource] += values[allocationOffset + process * resources + resource]
        finished[process] = true
        inc completed
        progress = true
    if not progress: return 0
  return 1
