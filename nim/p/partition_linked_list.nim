const MaxCount = 64
const Modulus = 1_000_000_007'i64
const Base = 2_000_000_003'i64
proc partition_linked_list*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "partition_linked_list".} =
  if v.isNil or n < 2 or n > 66 or v[0] < 0 or v[0] > MaxCount or n != csize_t(v[0] + 2) or v[1] < low(int32).int64 or v[1] > high(int32).int64: return -1
  let count=int(v[0]); var less, ge: array[MaxCount,int64]; var l=0; var g=0
  for i in 0..<count:
    let x=v[i+2]
    if x < low(int32).int64 or x > high(int32).int64: return -1
    if x<v[1]: less[l]=x; inc l else: ge[g]=x; inc g
  var h=0'i64
  for i in 0..<l: h=(h*Base+less[i]+2147483648'i64) mod Modulus
  for i in 0..<g: h=(h*Base+ge[i]+2147483648'i64) mod Modulus
  h
