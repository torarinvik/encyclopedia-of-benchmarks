const MaxLength = 4096
const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

proc isLocalMaximum(values: ptr UncheckedArray[int64], length, index: int): bool =
  if index == 0: return values[0] > values[1]
  if index == length - 1: return values[index] > values[index - 1]
  values[index] > values[index - 1] and values[index] > values[index + 1]

proc countRange(values: ptr UncheckedArray[int64], length, start, ending: int): int64 =
  if start == ending: return (if isLocalMaximum(values, length, start): 1'i64 else: 0'i64)
  let middle = (start + ending) div 2
  countRange(values, length, start, middle) + countRange(values, length, middle + 1, ending)

## Count strict local maxima using the pinned recursive partition.
proc number_of_local_maximum_points*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_local_maximum_points".} =
  if values == nil or length == 0 or length > MaxLength: return -1
  for i in 0 ..< int(length):
    if values[i] < Int32MinValue or values[i] > Int32MaxValue: return -1
  if length == 1: return 0 # Source compares the sole element with undefined.
  countRange(values, int(length), 0, int(length) - 1)
