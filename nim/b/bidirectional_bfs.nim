const N=64
const MaxArcs=4096
proc put(outp:ptr UncheckedArray[uint8],slot:int,v:int64)=
  let bits=cast[uint64](v)
  for i in 0..<8:outp[slot*8+i]=uint8((bits shr (8*i)) and 255)
proc bidirectional_bfs*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"bidirectional_bfs".}=
  if input==nil or length<4:return -1
  let nv=input[0];let av=input[1];let sv=input[2];let tv=input[3]
  if nv<1 or nv>N or av<0 or av>MaxArcs or sv<0 or sv>=nv or tv<0 or tv>=nv or int(length)!=4+2*int(av):return -1
  let n=int(nv);let m=int(av)
  var edge:array[N,array[N,bool]]
  var adj:array[N,array[N,int]]
  var deg:array[N,int]
  for i in 0..<m:
    let u=input[4+2*i];let v=input[5+2*i]
    if u<0 or u>=nv or v<0 or v>=nv:return -1
    if not edge[int(u)][int(v)]:
      edge[int(u)][int(v)]=true
      adj[int(u)][deg[int(u)]]=int(v)
      inc deg[int(u)]
  for u in 0..<n:
    for v in 0..<n:
      if edge[u][v]!=edge[v][u]:return -1
  let start=int(sv);let target=int(tv)
  var path:array[N,int]
  var pc=0
  if start==target:
    path[pc]=start
    inc pc
  else:
    var seen:array[2,array[N,bool]]
    var parent:array[2,array[N,int]]
    for s in 0..1:
      for i in 0..<n:parent[s][i]= -1
    var q:array[2,array[N,int]]
    var head,tail:array[2,int]
    seen[0][start]=true;seen[1][target]=true
    q[0][0]=start;q[1][0]=target;tail=[1,1]
    var meet= -1
    while head[0]<tail[0] and head[1]<tail[1] and meet<0:
      let end0=tail[0]
      while head[0]<end0:
        let u=q[0][head[0]]
        inc head[0]
        for j in 0..<deg[u]:
          let v=adj[u][j]
          if seen[0][v]:continue
          seen[0][v]=true;parent[0][v]=u;q[0][tail[0]]=v;inc tail[0]
      for v in 0..<n:
        if seen[0][v] and seen[1][v]:meet=v;break
      if meet>=0:break
      let end1=tail[1]
      while head[1]<end1:
        let u=q[1][head[1]]
        inc head[1]
        for j in 0..<deg[u]:
          let v=adj[u][j]
          if seen[1][v]:continue
          seen[1][v]=true;parent[1][v]=u;q[1][tail[1]]=v;inc tail[1]
      for v in 0..<n:
        if seen[0][v] and seen[1][v]:meet=v;break
    if meet>=0:
      var rev:array[N,int]
      var k=0
      var v=meet
      while v!= -1:
        rev[k]=v;inc k;v=parent[0][v]
      while k>0:
        dec k;path[pc]=rev[k];inc pc
      v=parent[1][meet]
      while v!= -1:
        path[pc]=v;inc pc;v=parent[1][v]
  let bytes=(1+pc)*8
  if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(pc))
  for i in 0..<pc:put(output,1+i,int64(path[i]))
  int64(bytes)
