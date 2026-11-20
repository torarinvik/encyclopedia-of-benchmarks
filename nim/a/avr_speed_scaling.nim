const
  MaxJobs = 8
  MaxTime = 8
  MaxSegments = 15
  MaxInputLength = 25
  MaxOutputValues = 79
  DensityScale = 840'i64

proc gcdI64(left, right: int64): int64 =
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc avr_speed_scaling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "avr_speed_scaling".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > int64(MaxJobs): return -1
  let count = int(countValue)
  if length != csize_t(1 + 3 * count): return -1

  var releases, deadlines: array[MaxJobs, int]
  var remaining: array[MaxJobs, int64]
  var finishNumerators, finishDenominators: array[MaxJobs, int64]
  var changes: array[MaxTime + 1, int64]
  var endpoint: array[MaxTime + 1, bool]
  for job in 0 ..< count:
    let offset = 1 + 3 * job
    let releaseValue = input[offset]
    let deadlineValue = input[offset + 1]
    let workValue = input[offset + 2]
    if releaseValue < 0 or releaseValue >= deadlineValue or deadlineValue > int64(MaxTime) or
        workValue < 1 or workValue > 8:
      return -1
    let release = int(releaseValue)
    let deadline = int(deadlineValue)
    let work = int(workValue)
    releases[job] = release
    deadlines[job] = deadline
    remaining[job] = int64(work) * DensityScale
    let scaledDensity = int64(work) * (DensityScale div int64(deadline - release))
    changes[release] += scaledDensity
    changes[deadline] -= scaledDensity
    endpoint[release] = true
    endpoint[deadline] = true

  var speedScaled = 0'i64
  var energyScaled = 0'i64
  var segments: array[MaxSegments, array[4, int64]]
  var segmentCount = 0
  for start in 0 ..< MaxTime:
    speedScaled += changes[start]
    if not endpoint[start]: continue
    var finish = start + 1
    while finish <= MaxTime and not endpoint[finish]: inc finish
    if finish > MaxTime or speedScaled <= 0: continue

    energyScaled += speedScaled * speedScaled * speedScaled * int64(finish - start)
    let speedDivisor = gcdI64(speedScaled, DensityScale)
    let speedNumerator = speedScaled div speedDivisor
    let speedDenominator = DensityScale div speedDivisor
    if segmentCount > 0 and segments[segmentCount - 1][1] == int64(start) and
        segments[segmentCount - 1][2] == speedNumerator and
        segments[segmentCount - 1][3] == speedDenominator:
      segments[segmentCount - 1][1] = int64(finish)
    else:
      segments[segmentCount] = [int64(start), int64(finish), speedNumerator, speedDenominator]
      inc segmentCount

    var cursorScaled = int64(start) * speedScaled
    let endScaled = int64(finish) * speedScaled
    while cursorScaled < endScaled:
      var selected = -1
      for job in 0 ..< count:
        if releases[job] <= start and start < deadlines[job] and remaining[job] > 0 and
            (selected < 0 or deadlines[job] < deadlines[selected]):
          selected = job
      if selected < 0: break
      let neededScaled = remaining[selected]
      if cursorScaled + neededScaled <= endScaled:
        cursorScaled += neededScaled
        remaining[selected] = 0
        let divisor = gcdI64(cursorScaled, speedScaled)
        finishNumerators[selected] = cursorScaled div divisor
        finishDenominators[selected] = speedScaled div divisor
      else:
        remaining[selected] -= endScaled - cursorScaled
        cursorScaled = endScaled

  let energyDenominator = DensityScale * DensityScale * DensityScale
  let energyDivisor = gcdI64(energyScaled, energyDenominator)
  var fields: array[MaxOutputValues, int64]
  var fieldCount = 0
  fields[fieldCount] = int64(segmentCount)
  inc fieldCount
  fields[fieldCount] = energyScaled div energyDivisor
  inc fieldCount
  fields[fieldCount] = energyDenominator div energyDivisor
  inc fieldCount
  for segment in 0 ..< segmentCount:
    for part in 0 ..< 4:
      fields[fieldCount] = segments[segment][part]
      inc fieldCount
  for job in 0 ..< count:
    if finishDenominators[job] <= 0: return -1
    fields[fieldCount] = finishNumerators[job]
    inc fieldCount
    fields[fieldCount] = finishDenominators[job]
    inc fieldCount

  let outputBytes = fieldCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for field in 0 ..< fieldCount:
    storeI64Le(output, field * 8, fields[field])
  int64(outputBytes)
