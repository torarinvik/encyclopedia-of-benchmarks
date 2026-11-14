proc highest_label_push_relabel*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "highest_label_push_relabel".} =
  if input.isNil or length < 4 or length > 197: return -1
  let nv=input[0]; let mv=input[1]; let sv=input[2]; let tv=input[3]
  if nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv: return -1
  let n=int(nv); let m=int(mv); let source=int(sv-1); let sink=int(tv-1)
  if length != csize_t(4+3*m): return -1
  var residual: array[256,int64]
  var excess: array[16,int64]
  var height: array[16,int]
  for i in 0 ..< m:
    let u=input[4+3*i]; let v=input[5+3*i]; let capacity=input[6+3*i]
    if u<1 or u>nv or v<1 or v>nv or u==v or capacity<0 or capacity>100: return -1
    residual[16*(int(u)-1)+int(v)-1] += capacity
  height[source]=n
  for v in 0 ..< n:
    let amount=residual[16*source+v]
    residual[16*source+v]=0
    residual[16*v+source]+=amount
    excess[v]+=amount
    excess[source]-=amount
  while true:
    var active = -1
    for v in 0 ..< n:
      if v!=source and v!=sink and excess[v]>0 and (active<0 or height[v]>height[active]): active=v
    if active<0: return excess[sink]
    var destination = -1
    var minimum=2*n+1
    for v in 0 ..< n:
      if residual[16*active+v]>0:
        minimum=min(minimum,height[v])
        if destination<0 and height[active]==height[v]+1: destination=v
    if destination<0:
      if minimum>2*n: return -1
      height[active]=minimum+1
    else:
      let amount=min(excess[active],residual[16*active+destination])
      residual[16*active+destination]-=amount
      residual[16*destination+active]+=amount
      excess[active]-=amount
      excess[destination]+=amount
