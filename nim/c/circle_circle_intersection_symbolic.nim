## Independently authored draft; not compiled or run.
proc circle_circle_intersection_symbolic*(v: ptr UncheckedArray[int64], n: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "circle_circle_intersection_symbolic".} =
  if v.isNil or n != 6: return -1
  for i in 0 ..< 6:
    if v[i] < -1000 or v[i] > 1000: return -1
  if v[2] < 1 or v[5] < 1: return -1
  let dx=v[3]-v[0]; let dy=v[4]-v[1]; let d=dx*dx+dy*dy
  var words: array[7,int64]
  var count=1
  if d == 0:
    words[0] = (if v[2] == v[5]: 3 else: 0)
  else:
    let t=d+v[2]*v[2]-v[5]*v[5]; let h=4*v[2]*v[2]*d-t*t
    if h >= 0:
      let den=2*d
      count=7
      words=[(if h == 0: 1'i64 else: 2'i64),den*v[0]+dx*t,den*v[1]+dy*t,den,-dy,dx,h]
  let needed=8*count
  if output.isNil or capacity < csize_t(needed): return -2
  for i in 0 ..< count:
    let bits=cast[uint64](words[i])
    for j in 0 ..< 8: output[8*i+j]=uint8((bits shr (8*j)) and 255'u64)
  int64(needed)
