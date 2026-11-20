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

proc solveSubset(outer: array[16,int], outerN:int, inner: array[6,int], k:int,
                 points: array[16,Point]):int64 =
  let states=1 shl k
  let sentinel=k
  var previous,current: array[448,int64]
  for cell in 0..<states*7:previous[cell]=Inf
  previous[sentinel]=0
  for mask in 0..<states:
    for last in 0..k:
      if last<k and (mask and (1 shl last))==0:continue
      let prefix=previous[mask*7+last]
      if prefix>=Inf:continue
      let vertex=if last==sentinel:outer[0] else:inner[last]
      for next in 0..<k:
        let bit=1 shl next
        if (mask and bit)!=0:continue
        let nextMask=mask or bit
        let candidate=addCost(prefix,distanceScaled(points[vertex],points[inner[next]]))
        previous[nextMask*7+next]=min(previous[nextMask*7+next],candidate)
  for i in 1..<outerN:
    for cell in 0..<states*7:current[cell]=Inf
    for mask in 0..<states:
      for last in 0..k:
        if last<k and (mask and (1 shl last))==0:continue
        let prefix=previous[mask*7+last]
        if prefix>=Inf:continue
        let vertex=if last==sentinel:outer[i-1] else:inner[last]
        let candidate=addCost(prefix,distanceScaled(points[vertex],points[outer[i]]))
        current[mask*7+sentinel]=min(current[mask*7+sentinel],candidate)
    for mask in 0..<states:
      for last in 0..k:
        if last<k and (mask and (1 shl last))==0:continue
        let prefix=current[mask*7+last]
        if prefix>=Inf:continue
        let vertex=if last==sentinel:outer[i] else:inner[last]
        for next in 0..<k:
          let bit=1 shl next
          if (mask and bit)!=0:continue
          let nextMask=mask or bit
          let candidate=addCost(prefix,distanceScaled(points[vertex],points[inner[next]]))
          current[nextMask*7+next]=min(current[nextMask*7+next],candidate)
    for cell in 0..<states*7:previous[cell]=current[cell]
  let full=states-1
  var best=Inf
  for last in 0..k:
    if last<k and (full and (1 shl last))==0:continue
    let vertex=if last==sentinel:outer[outerN-1] else:inner[last]
    best=min(best,addCost(previous[full*7+last],distanceScaled(points[vertex],points[outer[0]])))
  best

proc putI64(output: ptr UncheckedArray[uint8], x:int64)=
  let bits=cast[uint64](x)
  for b in 0..<8:output[b]=uint8((bits shr (8*b)) and 255)

proc tsp_few_inner_points_subset_dp*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64
    {.cdecl,exportc:"tsp_few_inner_points_subset_dp".} =
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
  let best=solveSubset(outer,outerN,inner,k,points)
  if output.isNil or int(capacity)<8:return -2
  putI64(output,best);return 8
