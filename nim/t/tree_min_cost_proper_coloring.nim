## Uncompiled bounded minimum-cost proper tree coloring draft.
proc tree_min_cost_proper_coloring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_min_cost_proper_coloring".} =
  if input == nil or length < 2 or length > 1090: return -1
  let nv=input[0]
  let kv=input[1]
  if nv<1 or nv>64 or kv<1 or kv>16: return -1
  let n=int(nv)
  let k=int(kv)
  if length!=csize_t(n+1+n*k): return -1
  for v in 1 ..< n:
    if input[1+v]<0 or input[1+v]>=int64(v): return -1
  var dp: array[64, array[16, int64]]
  for v in 0 ..< n:
    for c in 0 ..< k:
      let value=input[n+1+v*k+c]
      if value<0 or value>1_000_000: return -1
      dp[v][c]=value
  if n>1 and k==1: return -2
  var child=n-1
  while child>0:
    let parent=int(input[1+child])
    var least=high(int64)
    var second=high(int64)
    var bestColor=0
    for c in 0 ..< k:
      let value=dp[child][c]
      if value<least:
        second=least; least=value; bestColor=c
      elif value<second: second=value
    for c in 0 ..< k:
      dp[parent][c] += (if c==bestColor: second else: least)
    dec child
  result=dp[0][0]
  for c in 1 ..< k: result=min(result,dp[0][c])
