const MaxJobs = 4
const MaxSamples = 8
const MaxOutput = 136
const ENum = 271828'i64
const EDen = 100000'i64
const EM1Num = 171828'i64

proc gcd64(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  if a < 0: -a else: a

proc consider(release, deadline, work: array[MaxJobs, int64], n: int,
              t, xNum, xDen: int64, bestNum, bestDen: var int64) =
  let delta = xNum - t*xDen
  if delta <= 0: return
  let left = ENum*t*xDen - EM1Num*xNum
  var total = 0'i64
  for j in 0 ..< n:
    if release[j] <= t and left <= EDen*xDen*release[j] and deadline[j]*xDen <= xNum:
      total += work[j]
  let numerator = total*xDen
  if numerator*bestDen > bestNum*delta:
    bestNum = numerator
    bestDen = delta

proc put64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[at+byte] = uint8((bits shr (8*byte)) and 255)

proc bkp_speed_scaling_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bkp_speed_scaling_trace".} =
  if input.isNil or length < csize_t(2) or length > csize_t(31): return -1
  let n64 = input[0]
  let samples64 = input[1]
  if n64 < 1 or n64 > MaxJobs or samples64 < 1 or samples64 > MaxSamples: return -1
  let n = int(n64)
  let samples = int(samples64)
  if int64(length) != int64(2+3*n+2*samples): return -1
  var release, deadline, work: array[MaxJobs, int64]
  for j in 0 ..< n:
    release[j] = input[2+3*j]
    deadline[j] = input[3+3*j]
    work[j] = input[4+3*j]
    if release[j] < 0 or release[j] >= deadline[j] or deadline[j] > 8 or work[j] < 1 or work[j] > 8: return -1
  var values: array[1+2*MaxSamples, int64]
  values[0] = samples64
  let sampleStart = 2+3*n
  for s in 0 ..< samples:
    let t = input[sampleStart+2*s]
    let mask = input[sampleStart+2*s+1]
    if t < 0 or t > 8 or mask < 0 or mask >= (1'i64 shl n): return -1
    for j in 0 ..< n:
      if (mask and (1'i64 shl j)) != 0 and release[j] > t: return -1
    var bestNum = 0'i64
    var bestDen = 1'i64
    if mask != 0:
      for j in 0 ..< n:
        if release[j] <= t:
          if deadline[j] > t: consider(release, deadline, work, n, t, deadline[j], 1, bestNum, bestDen)
          if release[j] < t: consider(release, deadline, work, n, t, ENum*t-EDen*release[j], EM1Num, bestNum, bestDen)
    let divisor = gcd64(bestNum, bestDen)
    values[1+2*s] = bestNum div divisor
    values[2+2*s] = bestDen div divisor
  let outputBytes = 8*(1+2*samples)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutput, uint8]
  for i in 0 ..< 1+2*samples: put64(addr staged[0], 8*i, values[i])
  for i in 0 ..< outputBytes: output[i] = staged[i]
  int64(outputBytes)
