## Recursive maximum-difference pair with the pinned Python tie order.
type Pair = tuple[small, big: int64]
proc solve(values: ptr UncheckedArray[int64], start, n: int): Pair =
  if n == 1: return (values[start], values[start])
  let leftN = n div 2
  let left = solve(values, start, leftN)
  let right = solve(values, start + leftN, n - leftN)
  var minLeft = values[start]
  var maxRight = values[start + leftN]
  for i in start + 1 ..< start + leftN:
    if values[i] < minLeft: minLeft = values[i]
  for i in start + leftN + 1 ..< start + n:
    if values[i] > maxRight: maxRight = values[i]
  let cross = maxRight - minLeft
  let rightDiff = right.big - right.small
  let leftDiff = left.big - left.small
  if rightDiff > cross and rightDiff > leftDiff: return right
  if leftDiff > cross: return left
  (minLeft, maxRight)
proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)
proc max_difference_pair*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "max_difference_pair".} =
  if input.isNil or length < 2: return -1
  let n64 = input[0]
  if n64 < 1 or n64 > 128: return -1
  let n = int(n64)
  if length != csize_t(n + 1): return -1
  for i in 0..<n:
    if input[i+1] < -1_000_000 or input[i+1] > 1_000_000: return -1
  if output.isNil or capacity < 16: return -2
  let result = solve(input, 1, n)
  putI64Le(output, 0, result.small)
  putI64Le(output, 8, result.big)
  16
