proc putI64(outp: ptr UncheckedArray[byte], x: int64) =
  let u=cast[uint64](x)
  for b in 0 ..< 8: outp[b]=byte((u shr (8*b)) and 255)
proc mediabench_mpeg2_motion_vector_component*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[byte], capacity: csize_t): int64 {.cdecl,exportc:"mediabench_mpeg2_motion_vector_component".} =
  if values==nil or length!=4:return -1
  let pred=values[0];let rs=values[1];let code=values[2];let residual=values[3]
  if rs<0 or rs>6 or code < -16 or code>16:return -1
  let lim=16'i64 shl int(rs)
  if pred < -lim or pred>=lim:return -1
  if code==0 or rs==0:
    if residual!=0:return -1
  elif residual<0 or residual >= (1'i64 shl int(rs)):return -1
  var vector=pred
  if code>0:
    vector += ((code-1) shl int(rs))+residual+1
    if vector>=lim:vector-=2*lim
  elif code<0:
    vector -= ((-code-1) shl int(rs))+residual+1
    if vector < -lim:vector+=2*lim
  if output==nil or capacity<8:return -2
  putI64(output,vector)
  8
