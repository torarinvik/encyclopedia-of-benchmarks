## Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
const MaxLength = 4096

proc countForTarget(values: ptr UncheckedArray[int64], length: int, target: int64): int64 =
  var firstCount = 0'i64
  var middleCount = 0'i64
  var ways = 0'i64
  for index in 0 ..< length:
    if values[index] == target:
      ways += middleCount
      inc firstCount
    else:
      middleCount += firstCount
  ways

proc number_of_ways_to_select_buildings*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_ways_to_select_buildings".} =
  if length == 0: return 0
  if values == nil or length > MaxLength: return -1
  let n = int(length)
  for index in 0 ..< n:
    if values[index] != 48 and values[index] != 49: return -1
  countForTarget(values, n, 48) + countForTarget(values, n, 49)
