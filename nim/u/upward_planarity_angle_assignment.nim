## Clean-room fixed-embedding angle-assignment flow profile, DOI 653.
import std/algorithm
const N=8; const M=18; const F=12
proc put64(p: ptr UncheckedArray[uint8], k: int, x: int64) =
  let u=cast[uint64](x)
  for b in 0..<8: p[k*8+b]=uint8((u shr (8*b)) and 255)
proc aug(t,ns:int, slots:array[N,int], terms:array[N,int], inc:array[N*F,bool], owner:var array[N,int], seen:var array[N,bool], assigned:var array[N,int]):bool =
  for s in 0..<ns:
    if inc[terms[t]*F+slots[s]] and not seen[s]:
      seen[s]=true
      if owner[s]<0 or aug(owner[s],ns,slots,terms,inc,owner,seen,assigned): owner[s]=t;assigned[t]=s;return true
  false
proc suffixMatch(first,r,f:int, caps:array[F,int], slots:var array[N,int], terms:array[N,int], inc:array[N*F,bool]):bool =
  var ns=0;var owner,assigned:array[N,int];for i in 0..<N:owner[i]= -1;assigned[i]= -1
  for face in 0..<f:for _ in 0..<caps[face]:slots[ns]=face;inc ns
  for t in first..<r:var seen:array[N,bool];if not aug(t,ns,slots,terms,inc,owner,seen,assigned):return false
  true
proc upward_planarity_angle_assignment*(input: ptr UncheckedArray[int64], length:csize_t, output:ptr UncheckedArray[uint8], capacity:csize_t):int64 {.cdecl,exportc:"upward_planarity_angle_assignment".} =
  if input==nil or length<4 or length>124:return -1
  let n64=input[0];let m64=input[1];let f64=input[2];let o64=input[3]
  if n64<2 or n64>N or m64<1 or m64>M or f64<1 or f64>F or o64<0 or o64>=f64 or length!=csize_t(4+6*m64+f64):return -1
  let n=int(n64);let m=int(m64);let f=int(f64);let outer=int(o64)
  var eu,ev:array[M,int];var adj,oe:array[N*N,bool];var indeg:array[N,int]
  for i in 0..<m:
    let u=input[4+2*i];let v=input[5+2*i]
    if u<0 or u>=n64 or v<0 or v>=n64 or u==v:return -1
    if i>0 and (eu[i-1]>int(u) or (eu[i-1]==int(u) and ev[i-1]>=int(v))):return -1
    for j in 0..<i:if (eu[j]==int(u) and ev[j]==int(v)) or (eu[j]==int(v) and ev[j]==int(u)):return -1
    eu[i]=int(u);ev[i]=int(v);adj[int(u)*N+int(v)]=true;adj[int(v)*N+int(u)]=true;oe[int(u)*N+int(v)]=true;inc indeg[int(v)]
  var wl:array[F,int];var wu,wv:array[2*M,int];var dart:array[N*N,bool];var cursor=4+2*m;var total=0
  for j in 0..<f:
    let k=input[cursor];inc cursor
    if k<1 or k>2*m or total+int(k)>2*m:return -1
    wl[j]=int(k)
    for _ in 0..<int(k):
      let u=input[cursor];let v=input[cursor+1];cursor+=2
      if u<0 or v<0 or u>=n64 or v>=n64 or not adj[int(u)*N+int(v)] or dart[int(u)*N+int(v)]:return -1
      dart[int(u)*N+int(v)]=true;wu[total]=int(u);wv[total]=int(v);inc total
  if cursor!=int(length) or total!=2*m or n-m+f!=2:return -1
  for i in 0..<m:if not dart[eu[i]*N+ev[i]] or not dart[ev[i]*N+eu[i]]:return -1
  var succ:array[N*N,int];for i in 0..<N*N:succ[i]= -1
  var corner:array[F*N,int];for i in 0..<F*N:corner[i]= -1
  var incface:array[N*F,bool];var sw:array[F*2,int];cursor=0
  for j in 0..<f:
    let base=cursor;let k=wl[j]
    for i in 0..<k:
      let u=wu[cursor];let v=wv[cursor];let w=wv[base+(i+1) mod k]
      if v!=wu[base+(i+1) mod k] or succ[v*N+u]>=0:return -1
      succ[v*N+u]=w
      if corner[j*N+v]<0:corner[j*N+v]=i
      incface[v*F+j]=true
      if oe[v*N+u] and oe[v*N+w]:inc sw[j*2]
      if not oe[v*N+u] and not oe[v*N+w]:inc sw[j*2+1]
      inc cursor
  var reached:array[N,bool];var q:array[N,int];var h=0;var t=0;q[t]=0;inc t;reached[0]=true
  while h<t:let u=q[h];inc h;for v in 0..<n:if adj[u*N+v] and not reached[v]:reached[v]=true;q[t]=v;inc t
  for v in 0..<n:if not reached[v]:return -1
  var deg=indeg;h=0;t=0;for v in 0..<n:if deg[v]==0:q[t]=v;inc t
  var removed=0
  while h<t:let u=q[h];inc h;inc removed;for v in 0..<n:if oe[u*N+v]:dec deg[v];if deg[v]==0:q[t]=v;inc t
  if removed!=n:return -1
  for v in 0..<n:
    var d=0;for u in 0..<n:if adj[v*N+u]:inc d
    if d>0:
      var start= -1;for u in 0..<n:if adj[v*N+u]:if succ[v*N+u]<0:return -1;start=u
      var cur=start;var count=0;var trans=0
      while true:inc count;if count>d:return -1;let nxt=succ[v*N+cur];if oe[v*N+cur]!=oe[v*N+nxt]:inc trans;cur=nxt;if cur==start:break
      if count!=d or (trans!=0 and trans!=2):return -1
  var caps:array[F,int];var sum=0;var feasible=true
  for j in 0..<f:if sw[j*2]!=sw[j*2+1]:return -1;caps[j]=sw[j*2]+(if j==outer:1 else: -1);if caps[j]<0:feasible=false;sum+=caps[j]
  var terms:array[N,int];var r=0
  for v in 0..<n:var od=0;for u in 0..<n:if oe[v*N+u]:inc od;if indeg[v]==0 or od==0:terms[r]=v;inc r
  if sum!=r:feasible=false
  if output==nil or capacity<csize_t(8*(2+3*r)):return -2
  var slots,chosen:array[N,int];for i in 0..<N:chosen[i]= -1
  var ok=feasible
  for i in 0..<r:
    if ok:
      var found=false
      for face in 0..<f:
        if incface[terms[i]*F+face] and caps[face]>0:
          dec caps[face]
          if suffixMatch(i+1,r,f,caps,slots,terms,incface):chosen[i]=face;found=true;break
          inc caps[face]
      if not found:ok=false
  var words:array[26,int64];words[0]=if ok:1 else:0;words[1]=r;var z=2
  for i in 0..<r:
    if ok:let face=chosen[i];words[z]=terms[i];words[z+1]=face;words[z+2]=corner[face*N+terms[i]]
    else:words[z]= -1;words[z+1]= -1;words[z+2]= -1
    z+=3
  for i in 0..<z:put64(output,i,words[i])
  int64(z*8)
