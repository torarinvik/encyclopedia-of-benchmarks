const N=32
const M=256
const Q=64
type Path=object
  length:int64
  nodes:array[N,int64]
proc dfs(adj:var array[N,array[M,int]],degree:var array[N,int],at,dest:int,path:var array[N,int64],depth:int,visited:var array[N,bool]):int=
  if visited[at]:return -1
  visited[at]=true
  if at==dest:return depth
  for i in 0..<degree[at]:
    let next=adj[at][i]
    path[depth]=int64(next)
    let found=dfs(adj,degree,next,dest,path,depth+1,visited)
    if found>=0:return found
  -1
proc search(adj:var array[N,array[M,int]],degree:var array[N,int],mode,start,dest:int):Path=
  result.length = -1
  if mode==0:
    var path:array[N,int64]
    var visited:array[N,bool]
    let found=dfs(adj,degree,start,dest,path,0,visited)
    if found>=0:result.length=int64(found);result.nodes=path
    return
  var parent:array[N,int]
  for i in 0..<N:parent[i] = -1
  var queue:array[N,int]
  var head=0;var tail=0
  parent[start]=start;queue[tail]=start;inc tail
  while head<tail:
    let current=queue[head];inc head
    if current==dest:break
    for i in 0..<degree[current]:
      let next=adj[current][i]
      if parent[next] == -1:parent[next]=current;queue[tail]=next;inc tail
  if parent[dest] == -1:return
  var reverse:array[N,int]
  var count=0;var current=dest
  while current!=start:reverse[count]=current;inc count;current=parent[current]
  result.length=int64(count)
  for i in 0..<count:result.nodes[i]=int64(reverse[count-1-i])
proc putI64(output:ptr UncheckedArray[uint8],position:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[position+b]=uint8((bits shr (8*b)) and 255)
proc graph_swift_directed_paths*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"graph_swift_directed_paths".}=
  if input.isNil or length<3:return -1
  let n64=input[0];let m64=input[1]
  if n64<1 or n64>N or m64<0 or m64>M:return -1
  let qp=2+2*int(m64)
  if int(length)<qp+1:return -1
  let q64=input[qp]
  if q64<1 or q64>Q or int(length)!=qp+1+3*int(q64):return -1
  let n=int(n64);let m=int(m64);let q=int(q64)
  var adj:array[N,array[M,int]];var degree:array[N,int]
  for i in 0..<m:
    let u=input[2+2*i];let v=input[3+2*i]
    if u<0 or u>=n64 or v<=u or v>=n64:return -1
    adj[int(u)][degree[int(u)]]=int(v);inc degree[int(u)]
  var modes,starts,dests:array[Q,int]
  for i in 0..<q:
    let p=qp+1+3*i;let mode=input[p];let s=input[p+1];let d=input[p+2]
    if mode<0 or mode>1 or s<0 or s>=n64 or d<0 or d>=n64:return -1
    modes[i]=int(mode);starts[i]=int(s);dests[i]=int(d)
  var paths:array[Q,Path];var words=0
  for i in 0..<q:paths[i]=search(adj,degree,modes[i],starts[i],dests[i]);words+=1+(if paths[i].length>0:int(paths[i].length) else:0)
  let required=words*8
  if output.isNil or int(capacity)<required:return -2
  var pos=0
  for i in 0..<q:
    putI64(output,pos*8,paths[i].length);inc pos
    for j in 0..<int(max(paths[i].length,0'i64)):putI64(output,pos*8,paths[i].nodes[j]);inc pos
  int64(required)
