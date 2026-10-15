const MaxLength = 256

proc findMaxRange(values: ptr UncheckedArray[int64], lowIndex, highIndex: int): int64 =
  if lowIndex == highIndex: return values[lowIndex]
  let middle = lowIndex + (highIndex - lowIndex) div 2
  let left = findMaxRange(values, lowIndex, middle)
  let right = findMaxRange(values, middle + 1, highIndex)
  max(left, right)

proc find_max_recursion*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_max_recursion".} =
  if values == nil or length == 0 or length > csize_t(MaxLength): return -1
  for i in 0 ..< int(length):
    if values[i] < int64(low(int32)) or values[i] > int64(high(int32)): return -1
  findMaxRange(values, 0, int(length) - 1)
