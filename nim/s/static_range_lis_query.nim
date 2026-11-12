const MaxN = 128
const MaxQ = 32

proc lower(tails: array[MaxN, int64], count: int, value: int64): int =
  var lo = 0
  var hi = count
  while lo < hi:
    let mid = lo + (hi - lo) div 2
    if tails[mid] < value: lo = mid + 1 else: hi = mid
  lo

proc put64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc static_range_lis_query*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "static_range_lis_query".} =
  if input.isNil or int(length) < 2 or int(length) > 195: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxN or q64 < 1 or q64 > MaxQ: return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) != 2 + n + 2 * q: return -1
  var permutation, tails: array[MaxN, int64]
  var seen: array[MaxN, bool]
  var left, right, answers: array[MaxQ, int64]
  for i in 0 ..< n:
    let value = input[2 + i]
    if value < 0 or value >= n64 or seen[int(value)]: return -1
    seen[int(value)] = true
    permutation[i] = value
  var off = 2 + n
  for k in 0 ..< q:
    left[k] = input[off]
    right[k] = input[off + 1]
    off += 2
    if left[k] < 0 or left[k] > right[k] or right[k] > n64: return -1
  for k in 0 ..< q:
    var count = 0
    for i in int(left[k]) ..< int(right[k]):
      let at = lower(tails, count, permutation[i])
      tails[at] = permutation[i]
      if at == count: inc count
    answers[k] = int64(count)
  let bytes = 8 * q
  if output.isNil or int(capacity) < bytes: return -2
  for k in 0 ..< q: put64(output, 8 * k, answers[k])
  int64(bytes)
