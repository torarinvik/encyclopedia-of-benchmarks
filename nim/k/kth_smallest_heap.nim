proc down(h:var seq[int64],i0:int)=
 var i=i0
 while true:
  let l=2*i+1;let r=l+1;var m=i
  if l<h.len and h[l]>h[m]:m=l
  if r<h.len and h[r]>h[m]:m=r
  if m==i:break
  swap(h[i],h[m]);i=m
proc kth_smallest_heap*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kth_smallest_heap".}=
 if v.isNil or n<2 or n>65:return -1
 let k=v[0];if k<1 or k>=int64(n):return -1
 var h:seq[int64]=@[]
 for i in 0..<k:
  let x=v[i+1];if x< -100000 or x>100000:return -1
  h.add(x)
 for i in countdown(h.len div 2 - 1,0):down(h,i)
 for i in k+1..<n:
  let x=v[i];if x< -100000 or x>100000:return -1
  if x<=h[0]:h[0]=x;down(h,0)
 h[0]
