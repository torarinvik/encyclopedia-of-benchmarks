const MaxN=8;const MaxM=12;const MaxP=8;const MaxHops=56;const MaxInput=99
proc putI64(output:ptr UncheckedArray[uint8],word:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[word*8+b]=uint8((bits shr (8*b)) and 255'u64)
proc packet_routing_work_conserving_schedule*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"packet_routing_work_conserving_schedule".}=
  if input==nil or length<3 or length>MaxInput:return -1
  let n0=input[0];let m0=input[1];let p0=input[2]
  if n0<2 or n0>MaxN or m0<1 or m0>MaxM or p0<1 or p0>MaxP:return -1
  let n=int(n0);let m=int(m0);let p=int(p0);var at=3;if at+2*m>int(length):return -1
  var eu,ev:array[MaxM,int];var seen:array[MaxN,array[MaxN,bool]]
  for e in 0..<m:
    let u=input[at];let v=input[at+1];at+=2
    if u<0 or u>=n0 or v<0 or v>=n0 or u==v:return -1
    let lo=min(int(u),int(v));let hi=max(int(u),int(v));if seen[lo][hi]:return -1;seen[lo][hi]=true;eu[e]=int(u);ev[e]=int(v)
  var plen:array[MaxP,int];var paths:array[MaxP,array[MaxN,int]]
  for q in 0..<p:
    if at+2>int(length):return -1
    let start=input[at];let k=input[at+1];at+=2
    if start<0 or start>=n0 or k<1 or k>=n0 or at+int(k)>int(length):return -1
    plen[q]=int(k);var cur=int(start);var usedv:array[MaxN,bool];var usede:array[MaxM,bool];usedv[cur]=true
    for j in 0..<plen[q]:
      let e0=input[at];at+=1;if e0<0 or e0>=m0:return -1;let e=int(e0);if usede[e]:return -1;usede[e]=true;paths[q][j]=e
      if eu[e]==cur:cur=ev[e] elif ev[e]==cur:cur=eu[e] else:return -1
      if usedv[cur]:return -1;usedv[cur]=true
  if at!=int(length):return -1
  var pos:array[MaxP,int];var tt,te,tp:array[MaxHops,int64];var count=0;var time=0
  while true:
    var active=false;var chosen:array[MaxM,int];for e in 0..<m:chosen[e] = -1
    for q in 0..<p:
      if pos[q]<plen[q]:active=true;let e=paths[q][pos[q]];if chosen[e]<0:chosen[e]=q
    if not active:break
    for e in 0..<m:
      if chosen[e]>=0:
        if count>=MaxHops:return -1
        tt[count]=int64(time);te[count]=int64(e);tp[count]=int64(chosen[e]);count+=1;pos[chosen[e]]+=1
    time+=1;if time>MaxN*MaxP:return -1
  let words=2+3*count;let bytes=words*8
  if output==nil or capacity<csize_t(bytes):return -2
  putI64(output,0,int64(time));putI64(output,1,int64(count))
  for i in 0..<count:putI64(output,2+3*i,tt[i]);putI64(output,3+3*i,te[i]);putI64(output,4+3*i,tp[i])
  int64(bytes)
