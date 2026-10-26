# Clean-room exact branch-and-search vertex-cover profile.
const MaxN=16
const MaxInput=131
proc bitCount(x0:uint64):int =
  var x=x0
  while x!=0: result+=int(x and 1);x=x shr 1
proc search(adj:array[MaxN*MaxN,bool],n:int,active:uint64):uint64 =
  var chosen=n;var best=0;var any=false
  for u in 0..<n:
    if ((active shr u) and 1'u64) != 0:
      var degree=0
      for v in 0..<n: if ((active shr v) and 1'u64)!=0 and adj[u*MaxN+v]: inc degree
      if degree>0:
        any=true
        if chosen==n or degree>best:chosen=u;best=degree
  if not any:return 0
  let bit=1'u64 shl chosen
  let first=bit or search(adj,n,active and not bit)
  var neighbors=0'u64
  for v in 0..<n: if ((active shr v) and 1'u64)!=0 and adj[chosen*MaxN+v]:neighbors=neighbors or (1'u64 shl v)
  let second=neighbors or search(adj,n,active and not (neighbors or bit))
  let a=bitCount(first);let b=bitCount(second)
  if a<b:first elif b<a:second else:min(first,second)
proc put(outp:ptr UncheckedArray[uint8],at:int,x:int64)=
  let bits=cast[uint64](x)
  for i in 0..<8:outp[at+i]=uint8((bits shr (8*i)) and 255)
proc vertex_cover_search_trees*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"vertex_cover_search_trees".}=
  if input.isNil or length<3 or length>csize_t(MaxInput):return -1
  let n64=input[0];let m64=input[1];let k=input[2]
  if n64<1 or n64>16 or m64<0 or m64>64 or k<0 or k>n64 or int(length)!=3+2*int(m64):return -1
  let n=int(n64);let m=int(m64);var adj:array[MaxN*MaxN,bool];var pu:int64 = -1;var pv:int64 = -1
  for e in 0..<m:
    let u=input[3+2*e];let v=input[4+2*e]
    if u<0 or v<=u or v>=n64 or u<pu or (u==pu and v<=pv):return -1
    adj[int(u)*MaxN+int(v)]=true;adj[int(v)*MaxN+int(u)]=true;pu=u;pv=v
  if output.isNil or capacity<24:return -2
  let cover=search(adj,n,(1'u64 shl n)-1);let count=bitCount(cover)
  put(output,0,if count<=int(k):1 else:0);put(output,8,int64(count));put(output,16,cast[int64](cover));24
