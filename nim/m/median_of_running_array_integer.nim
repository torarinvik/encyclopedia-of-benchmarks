proc heapPush(h:var array[256,int64],count:var int,isMax:bool,x:int64)=
  var i=count;h[i]=x;inc count
  while i>0:
    let p=(i-1) div 2
    if (if isMax:h[p]>=h[i] else:h[p]<=h[i]):break
    swap(h[p],h[i]);i=p
proc heapPop(h:var array[256,int64],count:var int,isMax:bool):int64=
  result=h[0];dec count;h[0]=h[count];var i=0
  while true:
    let l=2*i+1;let r=l+1;var b=i
    if l<count and (if isMax:h[l]>h[b] else:h[l]<h[b]):b=l
    if r<count and (if isMax:h[r]>h[b] else:h[r]<h[b]):b=r
    if b==i:break
    swap(h[i],h[b]);i=b
proc store(value:int64,out:ptr UncheckedArray[uint8],p:int)=let u=cast[uint64](value);for b in 0..<8:out[p+b]=uint8((u shr (8*b)) and 255)
proc median_of_running_array_integer*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"median_of_running_array_integer".}=
  if input.isNil or length<2:return -1
  let n0=input[0];if n0<1 or n0>256 or int(length)!=int(n0)+1:return -1
  let n=int(n0);for i in 0..<n:if input[i+1]< -1_000_000 or input[i+1]>1_000_000:return -1
  if output.isNil or capacity<csize_t(n*8):return -2
  var lo,hi:array[256,int64];var nl=0;var nh=0
  for i in 0..<n:
    let x=input[i+1]
    if nh>0 and x<hi[0]:heapPush(lo,nl,true,x) else:heapPush(hi,nh,false,x)
    if nl>nh+1:heapPush(hi,nh,false,heapPop(lo,nl,true)) elif nh>nl+1:heapPush(lo,nl,true,heapPop(hi,nh,false))
    let med=if nl==nh:(lo[0]+hi[0]) div 2 elif nl>nh:lo[0] else:hi[0]
    store(med,output,i*8)
  int64(n*8)
