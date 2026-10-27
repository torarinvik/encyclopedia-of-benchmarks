import math

const MaxN=8; const MaxM=16; const MaxK=8; const MaxInput=75; const MaxOutput=648
proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0 ..< 8: output[offset+b]=uint8((bits shr (8*b)) and 255)

proc truthful_ufp_greedy1*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "truthful_ufp_greedy1".} =
  if values==nil or length<9 or length>csize_t(MaxInput): return -1
  if values[0]<2 or values[0]>MaxN or values[1]<1 or values[1]>MaxM or values[2]<1 or values[2]>MaxK: return -1
  let nv=int(values[0]);let m=int(values[1]);let k=int(values[2])
  if int(length)!=3+3*m+3*k:return -1
  var eu:array[MaxM,int];var ev:array[MaxM,int];var caps:array[MaxM,int];var prices:array[MaxM,float64]
  var minimum=9;var prevU = -1;var prevV = -1
  for e in 0 ..< m:
    let u=values[3+3*e];let v=values[4+3*e];let b=values[5+3*e]
    if u<0 or v<=u or v>=nv or b<2 or b>8 or (e>0 and (u<prevU or (u==prevU and v<=prevV))):return -1
    eu[e]=int(u);ev[e]=int(v);caps[e]=int(b);prices[e]=1.0/float64(b);minimum=min(minimum,int(b));prevU=u;prevV=v
  var src:array[MaxK,int];var dst:array[MaxK,int];var bid:array[MaxK,int]
  for i in 0 ..< k:
    let s=values[3+3*m+3*i];let t=values[4+3*m+3*i];let c=values[5+3*m+3*i]
    if s<0 or s>=nv or t<0 or t>=nv or s==t or c<1 or c>100:return -1
    src[i]=int(s);dst[i]=int(t);bid[i]=int(c)
  let threshold=pow(2.718281828459045,float64(minimum-1))*float64(m)
  var live:array[MaxK,bool];for i in 0 ..< k:live[i]=true
  var chosen:array[MaxK,int];var pathLen:array[MaxK,int];var paths:array[MaxK*MaxN,int];var count=0
  while count<k:
    var best = -1;var bestScore = -1.0
    var routeTable:array[MaxK*MaxN,int];var routeLen:array[MaxK,int]
    for i in 0 ..< k:
      if live[i]:
        var dist:array[MaxN,float64];var parent:array[MaxN,int];var used:array[MaxN,bool]
        for v in 0 ..< nv:dist[v]=1e300;parent[v] = -1
        dist[src[i]]=0.0
        for step in 0 ..< nv:
          var u = -1
          for v in 0 ..< nv:
            if not used[v] and (u<0 or dist[v]<dist[u] or (dist[v]==dist[u] and v<u)):u=v
          if u<0 or dist[u]>=1e299:break
          used[u]=true
          for e in 0 ..< m:
            var v = -1
            if eu[e]==u:v=ev[e]
            elif ev[e]==u:v=eu[e]
            if v>=0 and not used[v]:
              let candidate=dist[u]+prices[e]
              if candidate<dist[v] or (candidate==dist[v] and (parent[v]<0 or u<parent[v])):dist[v]=candidate;parent[v]=u
        if dist[dst[i]]>=1e299:return -1
        var reverse:array[MaxN,int];var len=0;var v=dst[i]
        while v!=src[i] and len<nv:
          reverse[len]=v;inc len
          if parent[v]<0:return -1
          v=parent[v]
        if v!=src[i] or len>=nv:return -1
        reverse[len]=src[i];inc len;routeLen[i]=len
        for q in 0 ..< len:routeTable[i*MaxN+q]=reverse[len-1-q]
        let score=float64(bid[i])/dist[dst[i]]
        if best<0 or score>bestScore:best=i;bestScore=score
    if best<0:break
    live[best]=false;chosen[count]=best;pathLen[count]=routeLen[best]
    for q in 0 ..< pathLen[count]:paths[count*MaxN+q]=routeTable[best*MaxN+q]
    inc count
    for q in 0 ..< pathLen[count-1]-1:
      let u=paths[(count-1)*MaxN+q];let v=paths[(count-1)*MaxN+q+1]
      for e in 0 ..< m:
        if (eu[e]==u and ev[e]==v) or (eu[e]==v and ev[e]==u):prices[e]*=pow(threshold,1.0/float64(caps[e]-1))
    var dual=0.0
    for e in 0 ..< m:dual+=float64(caps[e])*prices[e]
    if dual>=threshold:break
  var words=1
  for i in 0 ..< count:words+=2+pathLen[i]
  let bytes=8*words
  if output==nil or int(capacity)<bytes:return -2
  var staged:array[MaxOutput,uint8];putI64(addr staged[0],0,int64(count));var w=1
  for i in 0 ..< count:
    putI64(addr staged[0],8*w,int64(chosen[i]));inc w;putI64(addr staged[0],8*w,int64(pathLen[i]));inc w
    for q in 0 ..< pathLen[i]:putI64(addr staged[0],8*w,int64(paths[i*MaxN+q]));inc w
  for i in 0 ..< bytes:output[i]=staged[i]
  int64(bytes)
