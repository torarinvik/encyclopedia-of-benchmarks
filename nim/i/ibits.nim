proc ibits*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "ibits".} =
  if v.isNil or n!=1:return -1
  var x=v[0]
  if x<0 or x>=9007199254740992:return -1
  var count=0'i64
  while x!=0:count+=1;x=x shr 1
  count
