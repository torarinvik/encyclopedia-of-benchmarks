const MaxLength = 1024

proc calculate_median*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "calculate_median".} =
  if values == nil or length < 1 or length > MaxLength.csize_t: return low(int64)
  let count = length.int
  let middle = count div 2
  if count mod 2 == 1: return values[middle] * 2
  values[middle - 1] + values[middle]
