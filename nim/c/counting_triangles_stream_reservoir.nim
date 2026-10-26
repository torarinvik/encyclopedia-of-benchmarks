proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)

proc counting_triangles_stream_reservoir*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64
    {.cdecl,exportc:"counting_triangles_stream_reservoir".}=
  if input.isNil or length<6 or length>114:return -1
  let n0=input[0];let m0=input[1]
  if n0<2 or n0>8 or m0<1 or m0>28 or int(length)!=2+4*int(m0):return -1
  let n=int(n0);let m=int(m0)
  var seen:array[8,array[8,bool]]
  var edges:array[28,array[2,int64]]
  for i in 0..<m:
    let u=input[2+2*i];let v=input[3+2*i]
    if u<0 or v<=u or v>=n0 or seen[int(u)][int(v)]:return -1
    seen[int(u)][int(v)]=true;seen[int(v)][int(u)]=true;edges[i]=[u,v]
  let base=2+2*m
  for t in 1..m:
    for s in 0..<2:
      let r=input[base+2*(t-1)+s]
      if r<0 or r>=int64(t):return -1
  var slots:array[2,array[2,int64]]
  for s in 0..<2:slots[s]=[-1'i64,-1'i64]
  var staged:array[112,int64]
  var at=0
  for t in 1..m:
    for s in 0..<2:
      if input[base+2*(t-1)+s]==0:slots[s]=edges[t-1]
    for s in 0..<2:
      staged[at]=slots[s][0];inc at
      staged[at]=slots[s][1];inc at
  let bytes=16*m
  if output.isNil or int(capacity)<bytes:return -2
  for i in 0..<at:putI64(output,8*i,staged[i])
  int64(bytes)
