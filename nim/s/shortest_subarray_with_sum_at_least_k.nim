const
  MaxCount = 256
  MaxInput = 259

proc shortestSubarrayWithSumAtLeastK*(packed: ptr UncheckedArray[int64],
    length: csize_t): int64
    {.cdecl, exportc: "shortest_subarray_with_sum_at_least_k".} =
  if packed.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let target = packed[0]
  let count = packed[1]
  if target < -4096 or target > 4096 or count < 0 or count > MaxCount:
    return -1
  if length != csize_t(count) + csize_t(2): return -1
  let n = int(count)

  var prefix: array[MaxCount + 1, int64]
  for index in 0 ..< n:
    let value = packed[index + 2]
    if value < -1000 or value > 1000: return -1
    prefix[index + 1] = prefix[index] + value

  var deque: array[MaxCount + 1, int]
  var head = 0
  var tail = 0
  var best = n + 1
  for right in 0 .. n:
    while head < tail and prefix[right] - prefix[deque[head]] >= target:
      best = min(best, right - deque[head])
      inc head
    while head < tail and prefix[right] <= prefix[deque[tail - 1]]:
      dec tail
    deque[tail] = right
    inc tail
  if best <= n: return int64(best)
  return 0

