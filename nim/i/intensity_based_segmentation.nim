proc intensity_based_segmentation*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "intensity_based_segmentation".} =
  if v.isNil or n < 2 or n > 12: return -1
  let k=v[0]
  if k<0 or k>4 or n<=csize_t(k)+1 or n>csize_t(k)+8: return -1
  for j in 1..<n:
    if v[j]<0 or v[j]>255: return -1
  var outv=0'i64; var place=1'i64
  for p in csize_t(k)+1..<n:
    var label=0'i64
    for i in 0..<k:
      if v[p]>v[csize_t(i)+1]: label=i+1
    outv+=label*place;place*=5
  outv
