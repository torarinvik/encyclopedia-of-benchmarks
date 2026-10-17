const MaxN = 64

proc searchRecursive(items: array[MaxN, int32], left, right: int, target: int32): int =
  if left > right: return -1
  if items[left] == target: return left
  if items[right] == target: return right
  searchRecursive(items, left + 1, right - 1, target)

proc recursive_linear_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "recursive_linear_search".} =
  if input == nil or length < 4 or length > csize_t(MaxN + 2): return -1
  if input[0] < 2 or input[0] > MaxN or length != csize_t(input[0] + 2): return -1
  if input[1] < int64(low(int32)) or input[1] > int64(high(int32)): return -1
  let n = int(input[0])
  var items: array[MaxN, int32]
  for i in 0 ..< n:
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
    items[i] = int32(input[i + 2])
    for j in 0 ..< i:
      if items[j] == items[i]: return -1
  int64(searchRecursive(items, 0, n - 1, int32(input[1])))
