const MaxValues=512
proc choose(values:openArray[int64],tree:openArray[int],left,right:int):int=
  if tree[left]<0:return tree[right]
  if tree[right]<0:return tree[left]
  if values[tree[left]]<=values[tree[right]]:tree[left] else:tree[right]
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (b*8)) and 0xff'u64)
proc tournament_sort*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tournament_sort".}=
  if input.isNil or length<1:return -1
  let n64=input[0];if n64<0 or n64>MaxValues:return -1
  let n=int(n64);if length!=csize_t(1+n):return -1
  var values:array[MaxValues,int64]
  for i in 0..<n:
    let v=input[i+1];if v < -2147483648'i64 or v > 2147483647'i64:return -1
    values[i]=v
  var leaves=1;while leaves<n:leaves*=2
  var tree:array[2*MaxValues+1,int]
  for i in 0..<2*leaves:tree[i]= -1
  for i in 0..<n:tree[leaves+i]=i
  if leaves>1:
    for node in countdown(leaves-1,1):tree[node]=choose(values,tree,node*2,node*2+1)
  let bytes=(1+n)*8
  if output.isNil or capacity<csize_t(bytes):return -2
  putI64(output,0,int64(n))
  for outIndex in 0..<n:
    let w=tree[1];putI64(output,(1+outIndex)*8,values[w])
    var node=leaves+w;tree[node]= -1
    while node>1:node=node div 2;tree[node]=choose(values,tree,node*2,node*2+1)
  int64(bytes)
