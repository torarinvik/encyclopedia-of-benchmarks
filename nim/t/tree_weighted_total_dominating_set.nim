## Uncompiled weighted total-domination tree draft.
const inf = 1_000_000_000_000'i64
proc add(a,b:int64):int64 = min(inf,a+b)
proc tree_weighted_total_dominating_set*(input: ptr UncheckedArray[int64],length:csize_t):int64
    {.cdecl, exportc: "tree_weighted_total_dominating_set".} =
  if input==nil or length<2 or length>129: return -1
  let nv=input[0]
  if nv<1 or nv>64 or length!=csize_t(2*nv): return -1
  let n=int(nv)
  for v in 1 ..< n:
    if input[v]<0 or input[v]>=int64(v): return -1
  var weights: array[64,int64]
  var none,some: array[64,array[2,int64]]
  for v in 0 ..< n:
    weights[v]=input[n+v]
    if weights[v]<0 or weights[v]>1_000_000: return -1
    some[v]=[inf,inf]
  var root=inf
  var v=n-1
  while v>=0:
    var dp: array[2,array[2,int64]]
    for chosen in 0 .. 1:
      let own=if chosen==1: weights[v] else: 0'i64
      dp[chosen][0]=add(own,some[v][chosen])
      dp[chosen][1]=add(own,min(none[v][chosen],some[v][chosen]))
    if v==0:
      root=min(dp[0][0],dp[1][0])
      break
    let p=int(input[v])
    for chosen in 0 .. 1:
      let a=dp[0][chosen]
      let b=dp[1][chosen]
      let next=min(add(some[p][chosen],min(a,b)),add(none[p][chosen],b))
      none[p][chosen]=add(none[p][chosen],a)
      some[p][chosen]=next
    dec v
  if root==inf: -2 else: root
