const MaxLength=64
const Bound=1_000_000'i64
const InvalidResult = -1.0e300
proc arithmetic_mean*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "arithmetic_mean".} =
  if values==nil or length==0 or length>csize_t(MaxLength): return InvalidResult
  var total=0'i64
  for i in 0 ..< int(length):
    if values[i] < -Bound or values[i] > Bound: return InvalidResult
    total+=values[i]
  float64(total)/float64(length)
