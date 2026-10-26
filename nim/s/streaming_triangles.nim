proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)
proc power(base,exp:int):int=
  result=1
  for i in 0..<exp:result*=base
proc makeWedge(au,av,bu,bv:int64,x,y:var int64):bool=
  var common = -1'i64
  if au==bu or au==bv:common=au
  if av==bu or av==bv:common=av
  if common<0:return false
  x=if au==common:av else:au
  y=if bu==common:bv else:bu
  if x==y:return false
  if x>y:swap(x,y)
  true

proc streaming_triangles*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64
    {.cdecl,exportc:"streaming_triangles".}=
  if input.isNil or length<10 or length>340:return -1
  let n0=input[0];let m0=input[1];let se0=input[2];let sw0=input[3]
  if n0<2 or n0>8 or m0<1 or m0>28 or se0<2 or se0>4 or sw0<1 or sw0>4:return -1
  let n=int(n0);let m=int(m0);let se=int(se0);let sw=int(sw0);let stride=2+2*sw
  if int(length)!=4+2*m+m*stride:return -1
  var eu:array[28,int64];var ev:array[28,int64];var seen:array[8,array[8,bool]]
  for i in 0..<m:
    let u=input[4+2*i];let v=input[5+2*i]
    if u<0 or v<=u or v>=n0 or seen[int(u)][int(v)]:return -1
    seen[int(u)][int(v)]=true;seen[int(v)][int(u)]=true;eu[i]=u;ev[i]=v
  var edgeId:array[4,int];for s in 0..<4:edgeId[s] = -1
  var wedge:array[4,array[2,int64]];var wedgeValid:array[4,bool];var closed:array[4,bool]
  var total=0'i64;var staged:array[84,int64];var at=0;let tape=4+2*m
  for ti in 0..<m:
    let t=ti+1;let rec=tape+ti*stride
    for s in 0..<sw:
      if wedgeValid[s] and wedge[s][0]==eu[ti] and wedge[s][1]==ev[ti]:closed[s]=true
    let draw=input[rec];let slot0=input[rec+1];let lim=power(t,se);let threshold=lim-power(t-1,se)
    if draw<0 or draw>=int64(lim):return -1
    let update=draw<int64(threshold);var fresh:array[4,array[2,int64]];var freshCount=0;var removedCount=0
    if update:
      if slot0<0 or slot0>=int64(se):return -1
      let slot=int(slot0)
      if edgeId[slot]>=0:
        for j in 0..<se:
          if j!=slot and edgeId[j]>=0:
            var x,y:int64
            if makeWedge(eu[edgeId[slot]],ev[edgeId[slot]],eu[edgeId[j]],ev[edgeId[j]],x,y):inc removedCount
      edgeId[slot]=ti
      for j in 0..<se:
        if j!=slot and edgeId[j]>=0:
          var x,y:int64
          if makeWedge(eu[ti],ev[ti],eu[edgeId[j]],ev[edgeId[j]],x,y):fresh[freshCount]=[x,y];inc freshCount
    elif slot0!=0:return -1
    total+=int64(freshCount-removedCount)
    if total<0:return -1
    for s in 0..<sw:
      let wd=input[rec+2+2*s];let pick=input[rec+3+2*s]
      if freshCount>0:
        if wd<0 or wd>=total:return -1
        if wd<int64(freshCount):
          if pick<0 or pick>=int64(freshCount):return -1
          wedge[s]=fresh[int(pick)];wedgeValid[s]=true;closed[s]=false
        elif pick!=0:return -1
      elif wd!=0 or pick!=0:return -1
    var hits=0
    for s in 0..<sw:if closed[s]:inc hits
    staged[at]=total;staged[at+1]=(3*int64(hits)*1_000_000) div int64(sw)
    staged[at+2]=(int64(hits)*int64(t)*int64(t)*total*1_000_000) div int64(sw*se*(se-1));at+=3
  let bytes=24*m
  if output.isNil or int(capacity)<bytes:return -2
  for i in 0..<at:putI64(output,8*i,staged[i])
  int64(bytes)
