const MaxN = 32
const MaxInput = 35

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc max_sum_length_bounded_segment*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "max_sum_length_bounded_segment".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let lower64 = input[1]
  let upper64 = input[2]
  if n64 < 1 or n64 > int64(MaxN) or lower64 < 1 or upper64 < lower64 or upper64 > n64 or
      int64(length) != 3 + n64: return -1
  let n = int(n64)
  let lower = int(lower64)
  let upper = int(upper64)
  var prefix: array[MaxN + 1, int64]
  for i in 0..<n:
    let value = input[3 + i]
    if value < -10000 or value > 10000: return -1
    prefix[i + 1] = prefix[i] + value
  if output.isNil or capacity < csize_t(24): return -2
  var deque: array[MaxN + 1, int]
  var head = 0
  var tail = 0
  var bestSum = 0'i64
  var bestStart = 0
  var bestEnd = 0
  var haveBest = false
  for end in lower..n:
    let added = end - lower
    while tail > head and prefix[deque[tail - 1]] > prefix[added]: dec tail
    deque[tail] = added
    inc tail
    let earliest = if end > upper: end - upper else: 0
    while head < tail and deque[head] < earliest: inc head
    let start = deque[head]
    let total = prefix[end] - prefix[start]
    if not haveBest or total > bestSum or
        (total == bestSum and (start < bestStart or (start == bestStart and end < bestEnd))):
      bestSum = total
      bestStart = start
      bestEnd = end
      haveBest = true
  storeI64LE(output, 0, bestSum)
  storeI64LE(output, 8, int64(bestStart))
  storeI64LE(output, 16, int64(bestEnd))
  24
