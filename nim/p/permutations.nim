const MaxCount=6
proc mix(h:uint32,b:uint8):uint32=uint32((uint64(h xor uint32(b))*16777619'u64) and 0xFFFFFFFF'u64)
proc nextPerm(a:var array[MaxCount,int32],n:int):bool=
  var i=n-1
  while i>0 and a[i-1]>=a[i]:dec i
  if i==0:return false
  var j=n-1
  while a[j]<=a[i-1]:dec j
  swap(a[i-1],a[j]);var l=i;var r=n-1
  while l<r:swap(a[l],a[r]);inc l;dec r
  true
proc permutations*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"permutations".}=
  if v.isNil or n<2 or n>7 or v[0]<1 or v[0]>MaxCount or n!=csize_t(v[0]+1):return -1
  let count=int(v[0]);var a:array[MaxCount,int32]
  for i in 0..<count:
    if v[i+1]<low(int32).int64 or v[i+1]>high(int32).int64:return -1
    a[i]=int32(v[i+1]);if i>0 and a[i-1]>=a[i]:return -1
  var h=2166136261'u32
  while true:
    for value in a[0..<count]:
      let u=cast[uint32](value)
      for shift in [0,8,16,24]:h=mix(h,uint8(u shr shift))
    h=mix(h,255)
    if not nextPerm(a,count):break
  int64(h)
