const MaxN = 8
const MaxM = 16
const MaxWorlds = 8

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  var bits=cast[uint64](value)
  for byte in 0 ..< 8: output[word*8+byte]=uint8((bits shr (byte*8)) and 255'u64)

proc infectedCount(n,m,world:int,sources,protectors:uint16,eu,ev,masks:array[MaxM,int]):int =
  var states:array[MaxN,uint8]
  for v in 0 ..< n:
    if (sources and (1'u16 shl v))!=0'u16:states[v]=1
    if (protectors and (1'u16 shl v))!=0'u16:states[v]=2
  var rf,pf:array[MaxN,bool]
  for v in 0 ..< n:rf[v]=states[v]==1;pf[v]=states[v]==2
  step=0
  while step<n:
    var rp,pp,nr,np:array[MaxN,bool]
    for e in 0 ..< m:
      let u=eu[e];let v=ev[e]
      if states[v]!=0:continue
      if pf[u]:pp[v]=true
      if rf[u] and (masks[e] and (1 shl world))!=0:rp[v]=true
    var changed=false
    for v in 0 ..< n:
      if states[v]!=0:continue
      if pp[v]:states[v]=2;np[v]=true;changed=true
      elif rp[v]:states[v]=1;nr[v]=true;changed=true
    rf=nr;pf=np
    if not changed: break
    inc step
  for v in 0 ..< n:if states[v]==1:inc result

proc rumor_blocking_greedy_live_edge*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"rumor_blocking_greedy_live_edge".}=
  if input==nil or length<5 or length>61:return -1
  let n0=input[0];let m0=input[1];let r0=input[2];let k0=input[3];let w0=input[4]
  if n0<2 or n0>MaxN or m0<0 or m0>MaxM or r0<1 or r0>=n0 or k0<1 or k0>3 or w0<1 or w0>MaxWorlds or k0>n0-r0 or length!=csize_t(5+r0+3*m0):return -1
  let n=int(n0);let m=int(m0);let r=int(r0);let k=int(k0);let worlds=int(w0)
  var sources:uint16=0
  for i in 0 ..< r:
    let v=input[5+i]
    if v<0 or v>=n0 or (sources and (1'u16 shl int(v)))!=0'u16:return -1
    sources=sources or (1'u16 shl int(v))
  var eu,ev,masks:array[MaxM,int]
  var seen:array[MaxN,array[MaxN,bool]]
  let at=5+r;let allowed=(1 shl worlds)-1
  for e in 0 ..< m:
    let u=input[at+3*e];let v=input[at+3*e+1];let mask=input[at+3*e+2]
    if u<0 or u>=n0 or v<0 or v>=n0 or u==v or mask<0 or mask>allowed:return -1
    if seen[int(u)][int(v)]:return -1
    seen[int(u)][int(v)]=true;eu[e]=int(u);ev[e]=int(v);masks[e]=int(mask)
  var baseline:array[MaxWorlds,int]
  for world in 0 ..< worlds:baseline[world]=infectedCount(n,m,world,sources,0'u16,eu,ev,masks)
  var selected:uint16=0;var chosen,scores:array[MaxN,int]
  for round in 0 ..< k:
    var current:array[MaxWorlds,int]
    for world in 0 ..< worlds:current[world]=baseline[world]-infectedCount(n,m,world,sources,selected,eu,ev,masks)
    var bestNode = -1;var bestScore = -1
    for candidate in 0 ..< n:
      let bit=1'u16 shl candidate
      if (sources and bit)!=0'u16 or (selected and bit)!=0'u16:continue
      var score=0
      for world in 0 ..< worlds:score += baseline[world]-infectedCount(n,m,world,sources,selected or bit,eu,ev,masks)-current[world]
      if score>bestScore:bestNode=candidate;bestScore=score
    if bestNode<0:return -1
    selected=selected or (1'u16 shl bestNode);chosen[round]=bestNode;scores[round]=bestScore
  let bytes=(1+2*k)*8
  if output==nil or capacity<csize_t(bytes):return -2
  putI64Le(output,0,int64(k));var atOut=1
  for i in 0 ..< k:putI64Le(output,atOut,int64(chosen[i]));putI64Le(output,atOut+1,int64(scores[i]));atOut+=2
  int64(bytes)
