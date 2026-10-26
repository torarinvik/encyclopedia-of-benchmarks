# Clean-room bounded iterative-compression feedback vertex set profile.
const MaxN=8
const MaxInput=59
proc bitCount(x0:uint64):int=
  var x=x0
  while x!=0:result+=int(x and 1);x=x shr 1
proc findRoot(parent:var array[MaxN,int],value:int):int=
  var x=value
  while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
  x
proc isForest(adj:array[MaxN*MaxN,bool],n:int,vertices:uint64):bool=
  var parent:array[MaxN,int]
  for i in 0..<n:parent[i]=i
  for u in 0..<n:
    if ((vertices shr u) and 1'u64)!=0:
      for v in u+1..<n:
        if ((vertices shr v) and 1'u64)!=0 and adj[u*MaxN+v]:
          let a=findRoot(parent,u);let b=findRoot(parent,v)
          if a==b:return false
          parent[a]=b
  true
proc compress(adj:array[MaxN*MaxN,bool],n:int,prefix:uint64,k:int,current:uint64,result:var uint64):bool=
  var x=current
  while true:
    let cx=bitCount(x);let excluded=current and not x
    if cx<=k and isForest(adj,n,excluded):
      let eligible=prefix and not current
      var s=eligible
      while true:
        if bitCount(s)<=k-cx and isForest(adj,n,prefix and not (x or s)):
          result=x or s;return true
        if s==0:break
        s=(s-1) and eligible
    if x==0:break
    x=(x-1) and current
  false
proc solveBudget(adj:array[MaxN*MaxN,bool],n,k:int,answer:var uint64):bool=
  var fvs=0'u64
  for i in 0..<n:
    let prefix=(1'u64 shl (i+1))-1
    let candidate=fvs or (1'u64 shl i)
    if bitCount(candidate)<=k:fvs=candidate;continue
    var compressed=0'u64
    if not compress(adj,n,prefix,k,candidate,compressed):return false
    fvs=compressed
  answer=fvs;true
proc put(outp:ptr UncheckedArray[uint8],at:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:outp[at+b]=uint8((bits shr (8*b)) and 255)
proc undirected_feedback_vertex_set*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"undirected_feedback_vertex_set".}=
  if input.isNil or length<3 or length>csize_t(MaxInput):return -1
  let n64=input[0];let m64=input[1];let limit=input[2]
  if n64<1 or n64>8 or m64<0 or m64>28 or limit<0 or limit>4 or int(length)!=3+2*int(m64):return -1
  let n=int(n64);let m=int(m64);var adj:array[MaxN*MaxN,bool];var pu:int64 = -1;var pv:int64 = -1
  for e in 0..<m:
    let u=input[3+2*e];let v=input[4+2*e]
    if u<0 or v<=u or v>=n64 or u<pu or (u==pu and v<=pv):return -1
    adj[int(u)*MaxN+int(v)]=true;adj[int(v)*MaxN+int(u)]=true;pu=u;pv=v
  if output.isNil or capacity<16:return -2
  var found=false;var minimum = -1'i64;var answer=0'u64
  for budget in 0..int(limit):
    if solveBudget(adj,n,budget,answer):found=true;minimum=int64(budget);break
  put(output,0,if found:1 else:0);put(output,8,minimum);16
