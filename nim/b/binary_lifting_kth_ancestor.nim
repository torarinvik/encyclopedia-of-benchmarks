const MaxNodes=256
const MaxQueries=1024
const Levels=9
proc put(outp:ptr UncheckedArray[uint8],slot:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8:outp[slot*8+i]=uint8((bits shr (8*i)) and 255)
proc binary_lifting_kth_ancestor*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"binary_lifting_kth_ancestor".}=
  if input==nil or length<4 or input[0]<1 or input[0]>MaxNodes:return -1
  let n=int(input[0]);if input[1]<0 or input[1]>=n or input[2]!=n-1 or input[3]<0 or input[3]>MaxQueries:return -1
  let m=int(input[2]);let q=int(input[3]);let qo=4+2*m;if int(length)!=qo+2*q:return -1;let root=int(input[1])
  var adj:array[MaxNodes,array[MaxNodes,bool]]
  for e in 0..<m:
    let a=input[4+2*e];let b=input[5+2*e]
    if a<0 or b<0 or a>=n or b>=n or a==b:return -1
    adj[int(a)][int(b)]=true;adj[int(b)][int(a)]=true
  for i in 0..<q:
    let v=input[qo+2*i];let k=input[qo+2*i+1]
    if v<0 or v>=n or k<0:return -1
  var up:array[Levels,array[MaxNodes,int]];var parent:array[MaxNodes,int];var stack:array[MaxNodes,int];var top=0;var reached=0
  for i in 0..<n:parent[i]= -1
  parent[root]=root;up[0][root]=root;stack[top]=root;inc top
  while top>0:
    dec top;let u=stack[top];inc reached
    for v in 0..<n:
      if adj[u][v]:
        if v==parent[u]:continue
        if parent[v]!= -1:return -1
        parent[v]=u;up[0][v]=u;stack[top]=v;inc top
  if reached!=n:return -1
  for level in 1..<Levels:for v in 0..<n:up[level][v]=up[level-1][up[level-1][v]]
  let bytes=(1+q)*8;if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(q))
  for i in 0..<q:
    var v=int(input[qo+2*i]);let k=uint64(input[qo+2*i+1])
    if k>=uint64(n):
      v=root
    else:
      for bit in 0..<Levels:
        if (k and (1'u64 shl bit))!=0:v=up[bit][v]
    put(output,1+i,int64(v))
  int64(bytes)
