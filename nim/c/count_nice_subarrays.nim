const MaxLength = 4096

proc count_nice_subarrays*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_nice_subarrays".} =
  if values == nil or length < 2 or values[0] < 0 or values[0] > MaxLength or values[1] < 1 or values[1] > MaxLength: return -1
  let n = int(values[0])
  let k = int(values[1])
  if length != csize_t(n + 2): return -1
  for i in 0 ..< n:
    if values[i + 2] < int64(low(int32)) or values[i + 2] > int64(high(int32)): return -1
  var memo: array[MaxLength, int32]
  var left = 0
  var oddCount = 0
  var result = 0'i64
  for right in 0 ..< n:
    if (int32(values[right + 2]) and 1'i32) == 1: inc oddCount
    if oddCount > k:
      left += int(memo[left])
      dec oddCount
    if oddCount == k:
      if memo[left] == 0:
        var evenCount = 0
        var temp = left
        while (int32(values[temp + 2]) and 1'i32) == 0:
          inc evenCount
          inc temp
        memo[left] = int32(evenCount + 1)
      result += int64(memo[left])
  result
