const Scale = 16'i64
const MaxN = 12
const MaxSteps = 64
const MaxInput = 79
const MaxOutput = 208

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc ring_exact_covering_protocol*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "ring_exact_covering_protocol".} =
  if input.isNil or length < 3 or length > MaxInput: return -1
  if input[0] < 2 or input[0] > MaxN or input[2] < 0 or input[2] > MaxSteps: return -1
  let n = int(input[0]); let steps = int(input[2])
  if int(length) != 3 + n + steps: return -1
  let circumference = Scale * int64(n); let visibility = input[1]
  if visibility < 2 * Scale or visibility > circumference: return -1
  var position: array[MaxN, int64]
  for i in 0..<n:
    position[i] = input[3 + i]
    if position[i] < 0 or position[i] >= circumference or (i > 0 and position[i - 1] >= position[i]): return -1
  for j in 0..<steps:
    if input[3 + n + j] < 0 or input[3 + n + j] >= int64(n): return -1
  var moved = 0'i64
  for j in 0..<steps:
    let i = int(input[3 + n + j]); let next = (i + 1) mod n
    let gap = (position[next] - position[i] + circumference) mod circumference
    let distance = if gap > visibility: Scale elif gap > Scale: gap - Scale else: 0'i64
    if distance != 0:
      position[i] = (position[i] + distance) mod circumference
      inc moved
  let words = 2 + 2 * n; let bytes = 8 * words
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  put(addr staged[0], 0, int64(n)); put(addr staged[0], 8, moved)
  for i in 0..<n: put(addr staged[0], 8 * (2 + i), position[i])
  for i in 0..<n:
    let gap = (position[(i + 1) mod n] - position[i] + circumference) mod circumference
    put(addr staged[0], 8 * (2 + n + i), gap)
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
