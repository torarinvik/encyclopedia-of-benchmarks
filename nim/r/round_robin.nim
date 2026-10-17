type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

const MaxJobs = 32
const Quantum = 2'i64

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc round_robin*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "round_robin".} =
  if input == nil or length < 1: return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > MaxJobs or length != csize_t(rawCount + 1): return -1
  let count = int(rawCount)
  var remaining: array[MaxJobs, int64]
  var waiting: array[MaxJobs, int64]
  for i in 0..<count:
    let burst = input[i + 1]
    if burst < 0 or burst > 4096: return -1
    remaining[i] = burst
  let bytes = (1 + 2 * count) * 8
  if output == nil or capacity < csize_t(bytes): return -2
  var elapsed = 0'i64
  while true:
    var done = true
    for i in 0..<count:
      if remaining[i] > 0:
        done = false
        if remaining[i] > Quantum:
          elapsed += Quantum
          remaining[i] -= Quantum
        else:
          elapsed += remaining[i]
          waiting[i] = elapsed - input[i + 1]
          remaining[i] = 0
    if done: break
  putI64Le(output, 0, rawCount)
  for i in 0..<count: putI64Le(output, 8 * (1 + i), waiting[i])
  for i in 0..<count: putI64Le(output, 8 * (1 + count + i), input[i + 1] + waiting[i])
  int64(bytes)
