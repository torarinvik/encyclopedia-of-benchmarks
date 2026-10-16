proc heapPush(h:var array[64,int64],size:var int,x:int64)=
 var i=size;inc size
 while i>0 and h[(i-1) div 2]<x:h[i]=h[(i-1) div 2];i=(i-1) div 2
 h[i]=x
proc heapPop(h:var array[64,int64],size:var int):int64=
 result=h[0];dec size;let x=h[size];var i=0
 while 2*i+1<size:
  var c=2*i+1;if c+1<size and h[c+1]>h[c]:inc c
  if h[c]<=x:break
  h[i]=h[c];i=c
 if size>0:h[i]=x
proc minimize_deviation_in_array*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"minimize_deviation_in_array".}=
 if v.isNil or n<2 or n>65 or v[0]<1 or v[0]>64 or n!=csize_t(v[0]+1):return -1
 let count=int(v[0]);var h:array[64,int64];var size=0;var low=high(int64)
 for i in 0..<count:
  var x=v[i+1];if x<1 or x>1_000_000:return -1
  if (x mod 2)==1:x*=2
  low=min(low,x);heapPush(h,size,x)
 var best=h[0]-low
 while (h[0] mod 2)==0:
  let x=heapPop(h,size) div 2;low=min(low,x);heapPush(h,size,x);best=min(best,h[0]-low)
 best
