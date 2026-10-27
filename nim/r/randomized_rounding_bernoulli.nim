const MaxN = 16
const MaxInput = 65

proc randomized_rounding_bernoulli*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"randomized_rounding_bernoulli".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > MaxN or int64(length) != 1 + 4*n64: return -1
  let n = int(n64)
  var staged: array[MaxN, uint8]
  for i in 0..<n:
    let xNum=input[1+4*i]; let xDen=input[2+4*i]
    let uNum=input[3+4*i]; let uDen=input[4+4*i]
    if xDen < 1 or xDen > 32 or xNum < 0 or xNum > xDen or
       uDen < 1 or uDen > 32 or uNum < 0 or uNum >= uDen: return -1
    staged[i] = uint8(if uNum*xDen < xNum*uDen: 1 else: 0)
  if output.isNil or capacity < csize_t(n): return -2
  for i in 0..<n: output[i] = staged[i]
  int64(n)
