proc reversePoints(outp: ptr UncheckedArray[int64], start, count: int) =
  for i in 0 ..< count div 2:
    let a = start + 2 * i
    let b = start + 2 * (count - 1 - i)
    swap(outp[a], outp[b]); swap(outp[a + 1], outp[b + 1])
proc curve(x, y, side: int64, level, angle: int, outp: ptr UncheckedArray[int64], off: int): int =
  let q = side div 4
  let p = [(x+q,y+q),(x-q,y+q),(x-q,y-q),(x+q,y-q)]
  let a = ((angle mod 4) + 4) mod 4
  var r: array[4, tuple[x,y:int64]]
  for i in 0 ..< 4: r[i] = p[(i+a) mod 4]
  if level == 1:
    for i in 0 ..< 4: outp[off+2*i]=r[i].x; outp[off+2*i+1]=r[i].y
    return 4
  let h=side div 2
  let n=curve(r[0].x,r[0].y,h,level-1,a+1,outp,off); reversePoints(outp,off,n)
  let n1=curve(r[1].x,r[1].y,h,level-1,a,outp,off+2*n)
  let n2=curve(r[2].x,r[2].y,h,level-1,a,outp,off+2*(n+n1))
  let n3=curve(r[3].x,r[3].y,h,level-1,a-1,outp,off+2*(n+n1+n2)); reversePoints(outp,off+2*(n+n1+n2),n3)
  n+n1+n2+n3
proc hilbert_curve*(v: ptr UncheckedArray[int64], n: csize_t, outp: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "hilbert_curve".} =
  if v.isNil or n != 2: return -1
  if v[0] < 1 or v[0] > 6 or v[1] < 0 or v[1] > 3: return -1
  let level=int(v[0]);let points=1 shl (2*level);let bytes=points*16
  if outp.isNil or cap < csize_t(bytes): return -2
  var coords: array[8192,int64]
  discard curve(0,0,1'i64 shl (level+1),level,int(v[1]),cast[ptr UncheckedArray[int64]](addr coords[0]),0)
  for i in 0 ..< points*2:
    let bits=cast[uint64](coords[i])
    for k in 0 ..< 8: outp[i*8+k]=uint8((bits shr (8*k)) and 255)
  int64(bytes)
