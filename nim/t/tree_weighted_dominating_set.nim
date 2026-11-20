## Uncompiled weighted tree dominating-set draft.
const inf = 1_000_000_000_000'i64
proc capped(a,b: int64): int64 = min(inf,a+b)
proc tree_weighted_dominating_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_weighted_dominating_set".} =
  if input == nil or length<2 or length>129: return -1
  let nv=input[0]
  if nv<1 or nv>64 or length!=csize_t(2*nv): return -1
  let n=int(nv)
  for v in 1 ..< n:
    if input[v]<0 or input[v]>=int64(v): return -1
  var selected, covered, waiting: array[64, int64]
  for v in 0 ..< n:
    let weight=input[n+v]
    if weight<0 or weight>1_000_000: return -1
    selected[v]=weight
    covered[v]=inf
  var v=n-1
  while v>0:
    let p=int(input[v])
    let a=selected[v]
    let b=covered[v]
    let c=waiting[v]
    let next=min(capped(covered[p],min(a,b)),capped(waiting[p],a))
    selected[p]=capped(selected[p],min(min(a,b),c))
    waiting[p]=capped(waiting[p],b)
    covered[p]=next
    dec v
  min(selected[0],covered[0])
