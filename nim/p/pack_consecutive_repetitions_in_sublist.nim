proc mix(h:uint32,b:uint8):uint32=uint32((uint64(h xor uint32(b))*16777619'u64) and 0xFFFFFFFF'u64)
proc feed(h0:uint32,x:uint32):uint32=
  var h=h0
  for shift in [0,8,16,24]:h=mix(h,uint8(x shr shift))
  h
proc pack_consecutive_repetitions_in_sublist*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"pack_consecutive_repetitions_in_sublist".}=
  if v.isNil or n<1 or n>65 or v[0]<0 or v[0]>64 or n!=csize_t(v[0]+1):return -1
  let count=int(v[0])
  for i in 0..<count:
    if v[i+1]<low(int32).int64 or v[i+1]>high(int32).int64:return -1
  var h=2166136261'u32;var i=0
  while i<count:
    let value=int32(v[i+1]);var j=i+1
    while j<count and v[j+1]==int64(value):inc j
    h=feed(h,cast[uint32](value));h=feed(h,uint32(j-i));i=j
  int64(h)
