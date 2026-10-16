proc payback*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "payback".} =
 if v.isNil or n<1 or n>129 or v[0]<0 or v[0]>128 or n!=csize_t(v[0]+1):return -2
 var total=0'i64
 for i in 1..<int(n):
  if v[i]<-1_000_000 or v[i]>1_000_000:return -2
  total+=v[i]
  if total>=0:return int64(i-1)
 -1
