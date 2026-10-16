const N=64
const MaxArcs=N*(N-1)
proc put(outp:ptr UncheckedArray[uint8],slot:int,v:int64)=
  let b=cast[uint64](v)
  for i in 0..<8:outp[slot*8+i]=uint8((b shr (8*i)) and 255)
proc bidirectional_search*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"bidirectional_search".}=
  if input==nil or length<4 or input[0]<1 or input[0]>N:return -1
  let n=int(input[0]);if input[1]<0 or input[1]>=n or input[2]<0 or input[2]>=n or input[3]<0 or input[3]>MaxArcs or int(length)!=4+2*int(input[3]):return -1
  let m=int(input[3]);var adj:array[N,array[N-1,int]];var deg:array[N,int];var edge:array[N,array[N,bool]]
  for i in 0..<m:
    let u=input[4+2*i];let v=input[5+2*i]
    if u<0 or u>=n or v<0 or v>=n or u==v or edge[int(u)][int(v)]:return -1
    edge[int(u)][int(v)]=true;adj[int(u)][deg[int(u)]]=int(v);inc deg[int(u)]
  for u in 0..<n:for v in 0..<n:if edge[u][v]!=edge[v][u]:return -1
  var path:array[N,int];var pc=0;let start=int(input[1]);let goal=int(input[2])
  if start==goal:path[pc]=start;inc pc
  else:
    var parent:array[2,array[N,int]];for s in 0..1:for i in 0..<n:parent[s][i]= -2
    var q:array[2,array[N,int]];var head,tail:array[2,int];parent[0][start]= -1;parent[1][goal]= -1;q[0][0]=start;q[1][0]=goal;tail=[1,1];var meet= -1
    while head[0]<tail[0] and head[1]<tail[1] and meet<0:
      for s in 0..1:
        if meet>=0:break
        let cur=q[s][head[s]];inc head[s]
        for j in 0..<deg[cur]:
          let v=adj[cur][j];if parent[s][v]!= -2:continue
          parent[s][v]=cur;q[s][tail[s]]=v;inc tail[s]
          if parent[1-s][v]!= -2:meet=v;break
    if meet>=0:
      var rev:array[N,int];var k=0;var v=meet
      while v!= -1:rev[k]=v;inc k;v=parent[0][v]
      while k>0:dec k;path[pc]=rev[k];inc pc
      v=parent[1][meet];while v!= -1:path[pc]=v;inc pc;v=parent[1][v]
  let bytes=(1+pc)*8
  if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(pc));for i in 0..<pc:put(output,1+i,int64(path[i]))
  int64(bytes)
