proc local_binary_pattern*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "local_binary_pattern".} =
  if v.isNil or n!=9:return -1
  for i in 0..<9:
    if v[i]<0 or v[i]>255:return -1
  let ix=[2,5,1,8,7,6,3,0]
  var outv=0'i64
  for i in 0..<8:
    if v[ix[i]]>=v[4]:outv=outv or (1'i64 shl i)
  outv
