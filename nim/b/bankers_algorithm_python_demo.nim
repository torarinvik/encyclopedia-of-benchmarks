const MaxN = 16
const MaxM = 8

## Preserve duplicate-need bookkeeping in the pinned Python demonstration.
proc bankers_algorithm_python_demo*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "bankers_algorithm_python_demo".} =
  if values == nil or length < 5 or length > 266: return -1
  if values[0] < 1 or values[0] > MaxN or values[1] < 1 or values[1] > MaxM: return -1
  let n=int(values[0]); let m=int(values[1]); let aoff=2+m; let moff=aoff+n*m
  if length != csize_t(moff+n*m): return -1
  var work: array[MaxM,int64]
  for r in 0..<m:
    let x=values[2+r]; if x<0 or x>100: return -1
    work[r]=x
  for p in 0..<n:
    for r in 0..<m:
      let i=p*m+r; let a=values[aoff+i]; let x=values[moff+i]
      if a<0 or a>100 or x<0 or x>100 or a>x: return -1
      work[r]-=a
  for r in 0..<m: if work[r]<0: return -1
  var first,remaining: array[MaxN,int]
  for p in 0..<n:
    first[p]=p; remaining[p]=p
    for q in 0..<p:
      var equal=true
      for r in 0..<m:
        let pi=p*m+r;let qi=q*m+r
        if values[moff+pi]-values[aoff+pi] != values[moff+qi]-values[aoff+qi]: equal=false;break
      if equal: first[p]=first[q];break
  var count=n
  while count>0:
    var selected=count
    for i in 0..<count:
      let p=remaining[i];var feasible=true
      for r in 0..<m:
        let j=p*m+r
        if values[moff+j]-values[aoff+j]>work[r]: feasible=false;break
      if feasible: selected=i;break
    if selected==count: return 0
    let mapped=first[remaining[selected]]
    for r in 0..<m: work[r]+=values[aoff+mapped*m+r]
    for i in selected+1..<count: remaining[i-1]=remaining[i]
    dec count
  return 1
