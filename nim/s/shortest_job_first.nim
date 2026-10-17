type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

const MaxJobs = 32
const MaxArrival = 64'i64
const MaxBurst = 128'i64
const Sentinel = 999_999_999'i64

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc shortest_job_first*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "shortest_job_first".} =
  if input == nil or length < 1: return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > MaxJobs or length != csize_t(1 + 2 * rawCount): return -1
  let count = int(rawCount)
  var remaining: array[MaxJobs, int64]
  var waiting: array[MaxJobs, int64]
  for i in 0..<count:
    let arrival = input[1 + i]
    let burst = input[1 + count + i]
    if arrival < 0 or arrival > MaxArrival or burst < 1 or burst > MaxBurst or burst >= Sentinel: return -1
    remaining[i] = burst
  let bytes = (1 + 2 * count) * 8
  if output == nil or capacity < csize_t(bytes): return -2
  var complete = 0
  var time = 0'i64
  var minimum = Sentinel
  var shortIndex = 0
  var check = false
  while complete != count:
    for j in 0..<count:
      if input[1 + j] <= time and remaining[j] > 0 and remaining[j] < minimum:
        minimum = remaining[j]
        shortIndex = j
        check = true
    if not check:
      time += 1
      continue
    remaining[shortIndex] -= 1
    minimum = remaining[shortIndex]
    if minimum == 0: minimum = Sentinel
    if remaining[shortIndex] == 0:
      complete += 1
      check = false
      let finishTime = time + 1
      let wait = finishTime - input[1 + shortIndex] - input[1 + count + shortIndex]
      waiting[shortIndex] = max(wait, 0'i64)
    time += 1
  putI64Le(output, 0, rawCount)
  for i in 0..<count: putI64Le(output, 8 * (1 + i), waiting[i])
  for i in 0..<count: putI64Le(output, 8 * (1 + count + i), input[1 + count + i] + waiting[i])
  int64(bytes)
