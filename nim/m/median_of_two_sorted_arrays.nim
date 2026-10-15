## Merge two ascending i32 arrays and return twice their exact median.
const MaxTotalLength = 1024

proc median_of_two_sorted_arrays*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "median_of_two_sorted_arrays".} =
  if input == nil or length < 3 or length > MaxTotalLength + 2: return -1
  if input[0] < 0 or input[0] > MaxTotalLength or input[1] < 0 or input[1] > MaxTotalLength: return -1
  let firstCount = int(input[0])
  let secondCount = int(input[1])
  let totalCount = firstCount + secondCount
  if totalCount == 0 or totalCount > MaxTotalLength or int(length) != totalCount + 2: return -1
  let secondStart = firstCount + 2
  for index in 0 ..< firstCount:
    let value = input[index + 2]
    if value < int64(low(int32)) or value > int64(high(int32)) or
        (index != 0 and input[index + 1] > value): return -1
  for index in 0 ..< secondCount:
    let value = input[secondStart + index]
    if value < int64(low(int32)) or value > int64(high(int32)) or
        (index != 0 and input[secondStart + index - 1] > value): return -1

  var merged: array[MaxTotalLength, int32]
  var firstIndex = 0
  var secondIndex = 0
  var written = 0
  while firstIndex < firstCount and secondIndex < secondCount:
    if input[firstIndex + 2] <= input[secondStart + secondIndex]:
      merged[written] = int32(input[firstIndex + 2])
      inc firstIndex
    else:
      merged[written] = int32(input[secondStart + secondIndex])
      inc secondIndex
    inc written
  while firstIndex < firstCount:
    merged[written] = int32(input[firstIndex + 2])
    inc firstIndex
    inc written
  while secondIndex < secondCount:
    merged[written] = int32(input[secondStart + secondIndex])
    inc secondIndex
    inc written
  if totalCount mod 2 != 0: return int64(merged[totalCount div 2]) * 2
  int64(merged[totalCount div 2 - 1]) + int64(merged[totalCount div 2])
