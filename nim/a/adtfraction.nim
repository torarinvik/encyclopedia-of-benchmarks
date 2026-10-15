proc pack(n,d:int32):int64 =
  let bits = (uint64(cast[uint32](n)) shl 32) or uint64(cast[uint32](d))
  cast[int64](bits)
proc adtfraction*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "adtfraction".} =
  if length != 5: return -1
  for i in 0 ..< 5:
    if input[i] < -100000 or input[i] > 100000: return -1
  if input[0] < 0 or input[0] > 4: return -1
  let op=int32(input[0]); let n=int32(input[1]); let d=int32(input[2]); let m=int32(input[3]); let e=int32(input[4])
  case op
  of 0:
    if d==0 or e==0:return -1
    let den=cast[int32](cast[uint32](d)*cast[uint32](e)); if den==0:return -1
    return pack(cast[int32](cast[uint32](d)*cast[uint32](m)+cast[uint32](n)*cast[uint32](e)),den)
  of 1:
    if d==0:return -1
    return pack(cast[int32](cast[uint32](n)*cast[uint32](m)),d)
  of 2:
    if d==0 or e==0:return -1
    let den=cast[int32](cast[uint32](d)*cast[uint32](e)); if den==0:return -1
    return pack(cast[int32](cast[uint32](n)*cast[uint32](m)),den)
  of 3:
    if n==0:return -1
    return pack(d,n)
  else:
    if d==0:return -1
    return int64(cast[uint32](float32(n)/float32(d)))
