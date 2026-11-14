# Uncompiled and unexecuted matrix-tree draft.
type Matrix = array[36, int64]

proc minorDet(lap: Matrix, n, first, second: int): int64 =
  var matrix: Matrix
  var rows = 0
  for i in 0 ..< n:
    if i == first or i == second: continue
    var col = 0
    for j in 0 ..< n:
      if j != first and j != second:
        matrix[rows*6+col] = lap[i*6+j]
        inc col
    inc rows
  if rows == 0: return 1
  var previous = 1'i64
  for k in 0 ..< rows-1:
    let pivot = matrix[k*6+k]
    if pivot == 0: return 0
    for i in k+1 ..< rows:
      for j in k+1 ..< rows:
        matrix[i*6+j] = (matrix[i*6+j]*pivot - matrix[i*6+k]*matrix[k*6+j]) div previous
    for i in k+1 ..< rows: matrix[i*6+k] = 0
    previous = pivot
  matrix[(rows-1)*6+rows-1]

proc effective_resistance_unit_graph*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 4 or length > 35: return -1
  let nv=input[0]; let mv=input[1]; let sv=input[2]; let tv=input[3]
  if nv<2 or nv>6 or mv<0 or mv>15 or sv<0 or sv>=nv or tv<0 or tv>=nv or sv==tv or int(length)!=4+2*int(mv): return -1
  let n=int(nv); let m=int(mv); let s=int(sv); let t=int(tv)
  var lap: Matrix
  var seen: array[36, bool]
  for i in 0 ..< m:
    let uv=input[4+2*i]; let vv=input[5+2*i]
    if uv<0 or uv>=nv or vv<0 or vv>=nv or uv==vv: return -1
    let u=int(uv); let v=int(vv)
    if seen[u*6+v]: return -1
    seen[u*6+v]=true; seen[v*6+u]=true
    inc lap[u*6+u]; inc lap[v*6+v]; dec lap[u*6+v]; dec lap[v*6+u]
  let trees=minorDet(lap,n,t,-1)
  if trees<=0: return -1
  let forests=minorDet(lap,n,s,t)
  var a=trees; var b=forests
  while b!=0:
    let r=a mod b
    a=b; b=r
  forests div a * 65536 + trees div a
