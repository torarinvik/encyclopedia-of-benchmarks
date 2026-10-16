proc nextRng(state: var uint32): uint32 =
  var x=state;x=x xor (x shl 13);x=x xor (x shr 17);x=x xor (x shl 5);state=if x==0:0x9e3779b9'u32 else:x;state
proc partition(a: var array[128,int64],lo,hi:int):int=
  let pivot=a[hi];var i=lo
  for j in lo..<hi:
    if a[j]<=pivot:swap(a[i],a[j]);inc i
  swap(a[i],a[hi]);i
proc selectK(a:var array[128,int64],lo,hi,k:int,state:var uint32):int64=
  if lo==hi:return a[lo]
  let p=lo+int(nextRng(state) mod uint32(hi-lo+1));swap(a[p],a[hi]);let q=partition(a,lo,hi);let rank=q-lo+1
  if k==rank:return a[q]
  if k<rank:return selectK(a,lo,q-1,k,state)
  selectK(a,q+1,hi,k-rank,state)
proc minimum_element_of_array*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"minimum_element_of_array".}=
  if values.isNil or length<4:return -1
  let n=values[0];let k=values[1];let seed=values[2]
  if n<1 or n>128 or int(length)!=int(n)+3 or k<1 or k>n or seed<0 or seed>2_147_483_647:return -1
  var a:array[128,int64]
  for i in 0..<int(n):
    a[i]=values[i+3];if a[i]< -1_000_000 or a[i]>1_000_000:return -1
    for j in 0..<i:if a[i]==a[j]:return -1
  var state=if seed==0:0x9e3779b9'u32 else:uint32(seed)
  selectK(a,0,int(n)-1,int(k),state)
