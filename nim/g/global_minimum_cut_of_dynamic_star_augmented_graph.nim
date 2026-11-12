const MaxN=16
const MaxM=64
const MaxQ=32
const MaxV=17
const MaxInput=276
const MaxOutput=256
const MaxW=1_000_000'i64
proc storeLe(output:ptr UncheckedArray[uint8],at:int,x:int64)=
  let bits=cast[uint64](x)
  for b in 0..<8:output[at+b]=uint8((bits shr (8*b)) and 255'u64)
proc stoerWagner(n:int,spokes:array[MaxN,int64],m:int,eu,ev:array[MaxM,int64],ew:array[MaxM,int64]):int64=
  let vc=n+1
  var w:array[MaxV,array[MaxV,int64]]
  for e in 0..<m:
    let u=int(eu[e]);let v=int(ev[e]);w[u][v]+=ew[e];w[v][u]+=ew[e]
  for u in 0..<n:w[u][n]+=spokes[u];w[n][u]+=spokes[u]
  var active:array[MaxV,int];var count=vc
  for i in 0..<vc:active[i]=i
  var best=high(int64)
  while count>1:
    var used:array[MaxV,bool];var connection:array[MaxV,int64];var previous= -1
    for step in 0..<count:
      var selected= -1
      for z in 0..<count:
        let u=active[z]
        if not used[u] and (selected<0 or connection[u]>connection[selected] or (connection[u]==connection[selected] and u<selected)):selected=u
      if step+1==count:
        best=min(best,connection[selected])
        for z in 0..<count:
          let u=active[z]
          if u!=selected and u!=previous:w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u]
        var pos=0
        while active[pos]!=selected:inc pos
        for z in pos+1..<count:active[z-1]=active[z]
        dec count
        break
      used[selected]=true;previous=selected
      for z in 0..<count:
        let u=active[z]
        if not used[u]:connection[u]+=w[selected][u]
  best
proc global_minimum_cut_of_dynamic_star_augmented_graph*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"global_minimum_cut_of_dynamic_star_augmented_graph".}=
  if input==nil or length<3 or length>csize_t(MaxInput):return -1
  let n0=input[0];let m0=input[1];let q0=input[2]
  if n0<1 or n0>MaxN or m0<0 or m0>MaxM or m0>n0*(n0-1) div 2 or q0<1 or q0>MaxQ:return -1
  let n=int(n0);let m=int(m0);let q=int(q0)
  if int(length)!=3+n+3*m+2*q:return -1
  var pos=3;var spokes:array[MaxN,int64]
  for i in 0..<n:spokes[i]=input[pos];inc pos;if spokes[i]<0 or spokes[i]>MaxW:return -1
  var eu,ev,ew:array[MaxM,int64];var seen:array[MaxN,array[MaxN,bool]]
  for e in 0..<m:
    let u=input[pos];let v=input[pos+1];let weight=input[pos+2];pos+=3
    if u<0 or u>=n0 or v<0 or v>=n0 or u==v or weight<0 or weight>MaxW:return -1
    let a=int(min(u,v));let b=int(max(u,v));if seen[a][b]:return -1;seen[a][b]=true;eu[e]=u;ev[e]=v;ew[e]=weight
  var ux,uy:array[MaxQ,int64]
  for i in 0..<q:ux[i]=input[pos];uy[i]=input[pos+1];pos+=2;if ux[i]<0 or ux[i]>=n0 or uy[i]<0 or uy[i]>MaxW:return -1
  let bytes=8*q
  if bytes>MaxOutput:return -1
  if output==nil or int(capacity)<bytes:return -2
  var answers:array[MaxQ,int64]
  for i in 0..<q:spokes[int(ux[i])]=uy[i];answers[i]=stoerWagner(n,spokes,m,eu,ev,ew)
  for i in 0..<q:storeLe(output,8*i,answers[i])
  int64(bytes)
