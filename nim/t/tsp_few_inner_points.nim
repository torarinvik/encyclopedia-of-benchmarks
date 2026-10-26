type Point = object
  x, y: int64
const Inf = high(int64) div 4

proc distanceScaled(a,b: Point): int64 =
  let dx=a.x-b.x;let dy=a.y-b.y;let sq=(dx*dx+dy*dy)*1_000_000'i64
  var lo=0'i64;var hi=3_000_000'i64
  while lo<hi:
    let mid=lo+(hi-lo+1) div 2
    if mid*mid<=sq:lo=mid else:hi=mid-1
  let up=lo+1
  if up*up-sq<sq-lo*lo:up else:lo

proc addCost(a,b:int64):int64 = if a>=Inf: Inf else: a+b

proc solveOrder(outer: array[16,int], outerN:int, order: array[6,int], k:int,
                points: array[16,Point]):int64 =
  var po,pi,co,ci: array[7,int64]
  for j in 0..k:po[j]=Inf;pi[j]=Inf
  po[0]=0
  for j in 1..k:
    let a=addCost(po[j-1],distanceScaled(points[outer[0]],points[order[j-1]]))
    let b=if j>1:addCost(pi[j-1],distanceScaled(points[order[j-2]],points[order[j-1]])) else:Inf
    pi[j]=min(a,b)
  for i in 1..<outerN:
    for j in 0..k:co[j]=Inf;ci[j]=Inf
    let edge=distanceScaled(points[outer[i-1]],points[outer[i]])
    co[0]=addCost(po[0],edge)
    for j in 1..k:co[j]=min(addCost(po[j],edge),addCost(pi[j],distanceScaled(points[order[j-1]],points[outer[i]])))
    for j in 1..k:
      let a=addCost(co[j-1],distanceScaled(points[outer[i]],points[order[j-1]]))
      let b=if j>1:addCost(ci[j-1],distanceScaled(points[order[j-2]],points[order[j-1]])) else:Inf
      ci[j]=min(a,b)
    for j in 0..k:po[j]=co[j];pi[j]=ci[j]
  var best=addCost(po[k],distanceScaled(points[outer[outerN-1]],points[outer[0]]))
  if k>0:best=min(best,addCost(pi[k],distanceScaled(points[order[k-1]],points[outer[0]])))
  best

proc nextPerm(a: var array[6,int], n:int):bool =
  if n<2:return false
  var i=n-2
  while i>=0 and a[i]>=a[i+1]:dec i
  if i<0:return false
  var j=n-1
  while a[j]<=a[i]:dec j
  swap(a[i],a[j]);var l=i+1;var r=n-1
  while l<r:swap(a[l],a[r]);inc l;dec r
  true

proc putI64(output: ptr UncheckedArray[uint8], x:int64)=
  let bits=cast[uint64](x)
  for b in 0..<8:output[b]=uint8((bits shr (8*b)) and 255)

proc tsp_few_inner_points*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64
    {.cdecl,exportc:"tsp_few_inner_points".} =
  if input.isNil or length<2 or length>51:return -1
  let n0=input[0];let k0=input[1]
  if n0<3 or n0>16 or k0<0 or k0>6 or k0>n0-3 or int(length)!=2+3*int(n0):return -1
  let n=int(n0);let k=int(k0);let outerN=n-k
  var outer:array[16,int];var inner:array[6,int];var seen:array[16,bool]
  for i in 0..<outerN:
    let id=input[2+i];if id<0 or id>=n0 or seen[int(id)]:return -1
    outer[i]=int(id);seen[int(id)]=true
  for i in 0..<k:
    let id=input[2+outerN+i];if id<0 or id>=n0 or seen[int(id)]:return -1
    inner[i]=int(id);seen[int(id)]=true
  for i in 0..<n:if not seen[i]:return -1
  var points:array[16,Point];let off=2+n
  for i in 0..<n:
    let x=input[off+2*i];let y=input[off+2*i+1]
    if x< -1000 or x>1000 or y< -1000 or y>1000:return -1
    for j in 0..<i:if points[j].x==x and points[j].y==y:return -1
    points[i]=Point(x:x,y:y)
  for i in 1..<k:
    let x=inner[i];var j=i
    while j>0 and inner[j-1]>x:inner[j]=inner[j-1];dec j
    inner[j]=x
  var best=Inf
  while true:
    best=min(best,solveOrder(outer,outerN,inner,k,points))
    if not nextPerm(inner,k):break
  if output.isNil or int(capacity)<8:return -2
  putI64(output,best);return 8
