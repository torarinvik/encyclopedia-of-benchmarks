# Bounded ParGeo-style logarithmic batch-dynamic point forest; see package README/LICENSE.
import std/options
proc bdkInsert(levels: var array[6, array[32, int]], sizes: var array[6, int], id: int) =
  var carry: array[32, int]
  carry[0] = id
  var count = 1
  for level in 0 ..< 6:
    if sizes[level] == 0:
      for i in 0 ..< count: levels[level][i] = carry[i]
      sizes[level] = count
      return
    var next: array[32, int]
    var nextCount = 0
    for i in 0 ..< sizes[level]: next[nextCount] = levels[level][i]; inc nextCount
    for i in 0 ..< count: next[nextCount] = carry[i]; inc nextCount
    sizes[level] = 0
    for i in 0 ..< nextCount: carry[i] = next[i]
    count = nextCount

type BdkNode = object
  id, left, right: int
  minx, maxx, miny, maxy: int64
proc bdkBuild(ids: var seq[int], depth: int, x,y: array[32,int64], nodes: var array[32,BdkNode], used: var int): int =
  if ids.len == 0: return -1
  let axis = depth mod 2
  for i in 1 ..< ids.len:
    let v=ids[i];var j=i
    while j>0:
      let a=ids[j-1];let before=if axis==0: (x[v],y[v],v)<(x[a],y[a],a) else: (y[v],x[v],v)<(y[a],x[a],a)
      if not before: break
      ids[j]=ids[j-1];dec j
    ids[j]=v
  let mid=ids.len div 2;let id=ids[mid];let at=used;inc used
  var leftIds=ids[0 ..< mid];var rightIds:seq[int]=@[]
  for i in mid+1 ..< ids.len:rightIds.add(ids[i])
  let left=bdkBuild(leftIds,depth+1,x,y,nodes,used);let right=bdkBuild(rightIds,depth+1,x,y,nodes,used)
  nodes[at]=BdkNode(id:id,left:left,right:right,minx:x[id],maxx:x[id],miny:y[id],maxy:y[id])
  for child in [left,right]:
    if child>=0:
      nodes[at].minx=min(nodes[at].minx,nodes[child].minx);nodes[at].maxx=max(nodes[at].maxx,nodes[child].maxx)
      nodes[at].miny=min(nodes[at].miny,nodes[child].miny);nodes[at].maxy=max(nodes[at].maxy,nodes[child].maxy)
  at
proc bdkBox(n:BdkNode,qx,qy:int64):int64 =
  let dx=if qx<n.minx:n.minx-qx elif qx>n.maxx:qx-n.maxx else:0'i64
  let dy=if qy<n.miny:n.miny-qy elif qy>n.maxy:qy-n.maxy else:0'i64
  dx*dx+dy*dy
proc bdkQuery(at:int,nodes:array[32,BdkNode],x,y:array[32,int64],active:array[32,bool],qx,qy:int64,best:var Option[tuple[d:int64,id:int]]) =
  if at<0:return
  let n=nodes[at]
  if best.isSome and bdkBox(n,qx,qy)>best.get().d:return
  let id=n.id
  if active[id]:
    let dx=x[id]-qx;let dy=y[id]-qy;let candidate=(d:dx*dx+dy*dy,id:id)
    if best.isNone or candidate<best.get():best=some(candidate)
  var a=n.left;var b=n.right
  if a>=0 and b>=0 and bdkBox(nodes[b],qx,qy)<bdkBox(nodes[a],qx,qy):swap(a,b)
  bdkQuery(a,nodes,x,y,active,qx,qy,best);bdkQuery(b,nodes,x,y,active,qx,qy,best)

proc batch_dynamic_kd_tree*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "batch_dynamic_kd_tree".} =
  if input.isNil or inputLength < 2 or inputLength > 250: return -1
  let initialValue = input[0]
  if initialValue < 0 or initialValue > 8 or inputLength < (2+3*initialValue).csize_t: return -1
  var x, y: array[32, int64]
  var answers: array[8, int64]
  var ever, active: array[32, bool]
  var levels: array[6, array[32, int]]
  var sizes: array[6, int]
  var pos = 1
  var inserted = 0
  for _ in 0 ..< int(initialValue):
    let idValue=input[pos];inc pos;let px=input[pos];inc pos;let py=input[pos];inc pos
    if idValue < 0 or idValue >= 32 or ever[int(idValue)] or px < -1000 or px > 1000 or py < -1000 or py > 1000: return -1
    let id=int(idValue)
    for j in 0 ..< 32:
      if active[j] and x[j] == px and y[j] == py: return -1
    x[id]=px;y[id]=py;ever[id]=true;active[id]=true;inc inserted;bdkInsert(levels,sizes,id)
  if pos >= int(inputLength): return -1
  let batchValue=input[pos];inc pos
  if batchValue < 1 or batchValue > 8: return -1
  let batchCount=int(batchValue)
  for batch in 0 ..< batchCount:
    if pos+2 > int(inputLength): return -1
    let kind=input[pos];inc pos;let countValue=input[pos];inc pos
    if (kind != 0 and kind != 1) or countValue < 1 or countValue > 8: return -1
    let count=int(countValue)
    if kind == 0:
      if inserted+count > 32 or pos+3*count+2 > int(inputLength): return -1
      let recordStart=pos
      for j in 0 ..< count:
        let idValue=input[pos];inc pos;let px=input[pos];inc pos;let py=input[pos];inc pos
        if idValue < 0 or idValue >= 32 or ever[int(idValue)] or px < -1000 or px > 1000 or py < -1000 or py > 1000: return -1
        let id=int(idValue)
        for t in 0 ..< 32:
          if active[t] and x[t] == px and y[t] == py: return -1
        for t in 0 ..< j:
          if input[recordStart+3*t+1] == px and input[recordStart+3*t+2] == py: return -1
        x[id]=px;y[id]=py;ever[id]=true;active[id]=true;inc inserted;bdkInsert(levels,sizes,id)
    else:
      if pos+count+2 > int(inputLength): return -1
      for _ in 0 ..< count:
        let idValue=input[pos];inc pos
        if idValue < 0 or idValue >= 32 or not active[int(idValue)]: return -1
        active[int(idValue)]=false
    if pos+2 > int(inputLength): return -1
    let qx=input[pos];inc pos;let qy=input[pos];inc pos
    if qx < -1000 or qx > 1000 or qy < -1000 or qy > 1000: return -1
    var best=none(tuple[d:int64,id:int])
    for level in 0 ..< 6:
      if sizes[level]>0:
        var ids=newSeq[int](sizes[level]);for j in 0 ..< sizes[level]:ids[j]=levels[level][j]
        var nodes:array[32,BdkNode];var used=0;let root=bdkBuild(ids,0,x,y,nodes,used)
        bdkQuery(root,nodes,x,y,active,qx,qy,best)
    if best.isNone:return -1
    answers[batch]=best.get().d
  if pos != int(inputLength): return -1
  let needed=8*batchCount
  if output.isNil or outputCapacity < needed.csize_t: return -2
  for i in 0 ..< needed: output[i]=uint8((uint64(answers[i div 8]) shr (8*(i mod 8))) and 0xff)
  int64(needed)
