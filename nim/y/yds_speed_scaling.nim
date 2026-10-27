const MaxJobs = 4
const MaxTime = 8
const MaxInput = 13
const MaxOutput = 152

proc gcd64(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a

proc put64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc yds_speed_scaling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "yds_speed_scaling".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > int64(MaxJobs): return -1
  let n = int(n64)
  if int64(length) != int64(1 + 3*n): return -1
  var release, deadline: array[MaxJobs, int]
  var work: array[MaxJobs, int64]
  var active: array[MaxJobs, bool]
  for j in 0 ..< n:
    let r = input[1+3*j]
    let d = input[2+3*j]
    let w = input[3+3*j]
    if r < 0 or r >= d or d > int64(MaxTime) or w < 1 or w > 8: return -1
    release[j] = int(r)
    deadline[j] = int(d)
    work[j] = w
    active[j] = true
  var staged: array[MaxOutput div 8, int64]
  var outputValues = 3
  var stages = 0'i64
  var energyNum = 0'i64
  var energyDen = 1'i64
  var remaining = n
  while remaining > 0:
    var releaseSeen, deadlineSeen: array[MaxTime + 1, bool]
    for j in 0 ..< n:
      if active[j]:
        releaseSeen[release[j]] = true
        deadlineSeen[deadline[j]] = true
    var haveBest = false
    var bestA = 0
    var bestB = 1
    var bestWork = 0'i64
    var bestDuration = 1'i64
    var a = 0
    while a <= MaxTime:
      if releaseSeen[a]:
        var b = a + 1
        while b <= MaxTime:
          if deadlineSeen[b]:
            var total = 0'i64
            for j in 0 ..< n:
              if active[j] and release[j] >= a and deadline[j] <= b: total += work[j]
            if total > 0:
              let duration = int64(b-a)
              if not haveBest or total*bestDuration > bestWork*duration or
                  (total*bestDuration == bestWork*duration and (a < bestA or (a == bestA and b < bestB))):
                haveBest = true
                bestA = a
                bestB = b
                bestWork = total
                bestDuration = duration
          inc b
      inc a
    if not haveBest: return -1
    var jobMask = 0'i64
    for j in 0 ..< n:
      if active[j] and release[j] >= bestA and deadline[j] <= bestB:
        jobMask = jobMask or (1'i64 shl j)
    staged[outputValues] = int64(bestA); inc outputValues
    staged[outputValues] = int64(bestB); inc outputValues
    staged[outputValues] = bestWork; inc outputValues
    staged[outputValues] = jobMask; inc outputValues

    let termNum = bestWork*bestWork*bestWork
    let termDen = bestDuration*bestDuration
    let common = gcd64(energyDen, termDen)
    energyNum = energyNum*(termDen div common) + termNum*(energyDen div common)
    energyDen *= termDen div common
    let energyGcd = gcd64(energyNum, energyDen)
    energyNum = energyNum div energyGcd
    energyDen = energyDen div energyGcd

    for j in 0 ..< n:
      if not active[j]: continue
      if release[j] >= bestA and deadline[j] <= bestB:
        active[j] = false
        dec remaining
      else:
        if release[j] > bestA and release[j] < bestB: release[j] = bestA
        elif release[j] >= bestB: release[j] -= int(bestDuration)
        if deadline[j] > bestA and deadline[j] < bestB: deadline[j] = bestA
        elif deadline[j] >= bestB: deadline[j] -= int(bestDuration)
    inc stages
  staged[0] = stages
  staged[1] = energyNum
  staged[2] = energyDen
  let outputBytes = 8 * outputValues
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var bytes: array[MaxOutput, uint8]
  for i in 0 ..< outputValues: put64(addr bytes[0], 8*i, staged[i])
  for i in 0 ..< outputBytes: output[i] = bytes[i]
  int64(outputBytes)
