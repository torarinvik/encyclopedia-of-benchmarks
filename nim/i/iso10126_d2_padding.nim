proc iso10126_d2_padding*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"iso10126_d2_padding".}=
  if v==nil or n<2 or n>66:return -1
  let mode=v[0]
  if mode==0:
    if n<3:return -1
    let off=v[1];let length=v[2]
    if length<1 or length>64 or off<0 or off>=length or n!=csize_t(3+off+length-off-1):return -1
    for i in 3..<int(n):if v[i]<0 or v[i]>255:return -1
    for i in 3+int(off)..<int(n):if v[i]>=255:return -1
    let bytes=int(length)+1
    if outp==nil or cap<csize_t(bytes):return -2
    let count=uint8(length-off);outp[0]=count
    var at=1
    for i in 0..<int(off):outp[at]=uint8(v[3+i]);inc at
    for i in 3+int(off)..<int(n):outp[at]=uint8(v[i]);inc at
    outp[at]=count
    return int64(bytes)
  if (mode!=1 and mode!=2) or n<3:return -1
  let length=v[1]
  if length<1 or length>64 or n!=csize_t(2+length):return -1
  for i in 2..<int(n):if v[i]<0 or v[i]>255:return -1
  let count=v[int(n)-1]
  if count<1 or count>length:return -1
  let bytes=if mode==1:int(length-count) else:1
  if outp==nil or cap<csize_t(bytes):return -2
  if mode==1:
    for i in 0..<bytes:outp[i]=uint8(v[2+i])
  else:outp[0]=uint8(count)
  int64(bytes)
