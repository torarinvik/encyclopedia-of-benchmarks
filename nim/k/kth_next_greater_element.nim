proc kth_next_greater_element*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "kth_next_greater_element".} =
  if v.isNil or n<2 or n>8:return -1
  let k=v[0]
  if k<1 or k>7:return -1
  for q in 1..<n:
    if v[q]< -15 or v[q]>15:return -1
  let m=n-1
  var count=0'i64
  for i in 0..<m:
    var cur=v[i+1];var pos=i+1;var ok=true
    for z in 0..<k:
      while pos<m and v[pos+1]<=cur:pos+=1
      if pos==m:ok=false;break
      cur=v[pos+1];pos+=1
    if ok:count+=1
  count
