const MaxJobs = 8
const MaxTime = 1000'i64

proc solve(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if input.isNil or length < csize_t(1): return -1
  if input[0] < 1 or input[0] > int64(MaxJobs): return -1
  let count = int(input[0])
  if length != csize_t(1 + 2 * count): return -1
  var first, second: array[MaxJobs, int64]
  var early, late: array[MaxJobs, int]
  var earlyCount = 0
  var lateCount = 0
  for job in 0 ..< count:
    first[job] = input[1 + 2 * job]
    second[job] = input[2 + 2 * job]
    if first[job] < 0 or first[job] > MaxTime or second[job] < 0 or second[job] > MaxTime: return -1
    let isEarly = first[job] < second[job]
    var position = if isEarly: earlyCount else: lateCount
    while position > 0:
      let previous = if isEarly: early[position - 1] else: late[position - 1]
      let comesBefore = if isEarly:
        (first[job] < first[previous] or (first[job] == first[previous] and job < previous))
      else:
        (second[job] > second[previous] or (second[job] == second[previous] and job < previous))
      if not comesBefore: break
      if isEarly: early[position] = previous else: late[position] = previous
      position -= 1
    if isEarly:
      early[position] = job
      earlyCount += 1
    else:
      late[position] = job
      lateCount += 1
  var firstFinish = 0'i64
  var secondFinish = 0'i64
  for index in 0 ..< count:
    let job = if index < earlyCount: early[index] else: late[index - earlyCount]
    firstFinish += first[job]
    secondFinish = max(secondFinish, firstFinish) + second[job]
  secondFinish

proc johnson_two_machine_flow_shop*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "johnson_two_machine_flow_shop".} =
  solve(input, length)
