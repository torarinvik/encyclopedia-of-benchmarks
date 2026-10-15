const MaxLength=64
const Bound=1_000_000'i64
proc is_arithmetic_series*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "is_arithmetic_series".} =
  if values==nil or length==0 or length>csize_t(MaxLength): return -1
  for i in 0 ..< int(length):
    if values[i] < -Bound or values[i] > Bound: return -1
  if length==1: return 1
  let difference=values[1]-values[0]
  for i in 1 ..< int(length)-1:
    if values[i+1]-values[i]!=difference: return 0
  1
