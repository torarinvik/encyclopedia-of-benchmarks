const N = 1023
proc diff_views_of_binary_tree(a0: ptr int64, n0: csize_t, root: int64, view: int64,
    out0: ptr int64, cap0: csize_t): int64 {.exportc, cdecl.} =
  let n = int(n0)
  let cap = int(cap0)
  if n > N or view < 0 or view > 3: return -1
  if n == 0: return (if root == -1: 0 else: -1)
  if a0 == nil or root < 0 or root >= n: return -1
  if out0 == nil or cap < n: return -2
  let a = cast[ptr UncheckedArray[int64]](a0)
  let output = cast[ptr UncheckedArray[int64]](out0)
  var parents: array[N, int]
  for i in 0..<n:
    let v = a[3*i]
    let l = a[3*i+1]
    let r = a[3*i+2]
    if v < int64(low(int32)) or v > int64(high(int32)) or l < -1 or r < -1 or l >= n or r >= n: return -1
    for ch in [l,r]:
      if ch >= 0:
        inc parents[int(ch)]
        if parents[int(ch)] > 1: return -1
  if parents[int(root)] != 0: return -1
  for i in 0..<n:
    if i != int(root) and parents[i] != 1: return -1
  var q, depth: array[N, int]
  var col: array[N, int]
  var seen: array[N, bool]
  var fd, ld: array[N, int64]
  var fc, lc: array[2*N+1, int64]
  let sentinel = low(int64)
  for i in 0..<N: fd[i]=sentinel; ld[i]=sentinel
  for i in 0..<(2*N+1): fc[i]=sentinel; lc[i]=sentinel
  var head=0; var tail=1; var maxd=0; var minc=0; var maxc=0
  q[0]=int(root); seen[int(root)]=true
  while head < tail:
    let u=q[head]; inc head
    let d=depth[u]; let c=col[u]; let v=a[3*u]
    maxd=max(maxd,d); minc=min(minc,c); maxc=max(maxc,c)
    if fd[d]==sentinel: fd[d]=v
    ld[d]=v
    let s=c+N
    if fc[s]==sentinel: fc[s]=v
    lc[s]=v
    for k in 0..1:
      let ch=a[3*u+1+k]
      if ch>=0:
        let x=int(ch)
        if seen[x]: return -1
        seen[x]=true; depth[x]=d+1; col[x]=c+(if k==0: -1 else: 1); q[tail]=x; inc tail
  if tail != n: return -1
  var written=0
  if view<2:
    for d in 0..maxd:
      let v=if view==0: ld[d] else: fd[d]
      if v!=sentinel: output[written]=v; inc written
  else:
    for c in minc..maxc:
      let v=if view==2: fc[c+N] else: lc[c+N]
      if v!=sentinel: output[written]=v; inc written
  return int64(written)
