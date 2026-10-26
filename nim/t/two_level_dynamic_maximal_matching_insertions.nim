const N=9
const Q=24
const R=4
type Mat=array[81,bool]
type Vec=array[9,int]
proc put64(o:ptr UncheckedArray[uint8],at:int,x:int64)=
  let b=cast[uint64](x)
  for i in 0..<8:o[at+i]=uint8((b shr (8*i)) and 255)
proc owned(g:Mat,level:Vec,n,u:int,list:var Vec):int=
  for v in 0..<n:
    if g[u*N+v] and level[u]==0 and level[v]==0:list[result]=v;inc result
proc repair(g:Mat,level:Vec,mate:var Vec,n,u:int)=
  if u<0 or level[u]!=0 or mate[u]>=0:return
  for v in 0..<n:
    if g[u*N+v] and level[v]==0 and mate[v]<0:mate[u]=v;mate[v]=u;return
proc promote(g:Mat,level:var Vec,mate:var Vec,n,u:int,tape:array[R,int],r:int,used:var int):bool=
  var list:Vec;let count=owned(g,level,n,u,list)
  if count==0 or used>=r or tape[used]>=count:return false
  let y=list[tape[used]];inc used;let w=mate[u];let x=mate[y]
  if w>=0:mate[w] = -1;mate[u] = -1
  if x>=0:mate[x] = -1;mate[y] = -1
  level[u]=1;level[y]=1;mate[u]=y;mate[y]=u
  repair(g,level,mate,n,w);if x!=w:repair(g,level,mate,n,x)
  true
proc two_level_dynamic_maximal_matching_insertions*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"two_level_dynamic_maximal_matching_insertions".}=
  if input==nil or length<3 or length>55:return -1
  let n0=input[0];let q0=input[1]
  if (n0!=4 and n0!=9) or q0<0 or q0>Q or q0>n0*(n0-1) div 2:return -1
  let n=int(n0);let q=int(q0);var us,vs:array[Q,int];var seen:array[81,bool];var p=2
  for e in 0..<q:
    let u0=input[p];let v0=input[p+1];p+=2
    if u0<0 or v0<=u0 or v0>=n0 or seen[int(u0)*N+int(v0)]:return -1
    seen[int(u0)*N+int(v0)]=true;us[e]=int(u0);vs[e]=int(v0)
  if p>=int(length):return -1
  let r0=input[p];inc p
  if r0<0 or r0>R or int(length)!=p+int(r0):return -1
  let r=int(r0);var tape:array[R,int]
  for i in 0..<r:
    let x=input[p+i]
    if x<0 or x>=n0:return -1
    tape[i]=int(x)
  var graph:Mat;var level:Vec;var mate:Vec
  for i in 0..<n:mate[i] = -1
  var used=0;let threshold=if n==4:2 else:3
  for e in 0..<q:
    let u=us[e];let v=vs[e];graph[u*N+v]=true;graph[v*N+u]=true
    if level[u]==1 or level[v]==1:continue
    if mate[u]<0 and mate[v]<0:mate[u]=v;mate[v]=u
    var tmp:Vec;let du=owned(graph,level,n,u,tmp);let dv=owned(graph,level,n,v,tmp)
    let who=if du>dv or (du==dv and u<v):u else:v
    let count=owned(graph,level,n,who,tmp)
    if count>=threshold and not promote(graph,level,mate,n,who,tape,r,used):return -1
  if used!=r:return -1
  let bytes=8*(1+2*n)
  if output==nil or capacity<csize_t(bytes):return -2
  put64(output,0,int64(n))
  for i in 0..<n:put64(output,8+8*i,int64(level[i]))
  for i in 0..<n:put64(output,8+8*n+8*i,int64(mate[i]))
  int64(bytes)
