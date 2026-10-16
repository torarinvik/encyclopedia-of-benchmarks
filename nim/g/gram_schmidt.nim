import std/[math]
proc putF64(outp: ptr UncheckedArray[uint8], at: int, x: float64) =
  let bits = cast[uint64](x)
  for i in 0..<8: outp[at+i] = uint8((bits shr (8*i)) and 255)
proc gram_schmidt*(v: ptr UncheckedArray[int64], n: csize_t, outp: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "gram_schmidt".} =
  if v == nil or n < 2 or n > 18: return -1
  let rows=v[0]; let dim=v[1]
  if rows<1 or rows>4 or dim<rows or dim>4 or n!=csize_t(2+rows*dim): return -1
  var a,q: array[4,array[4,float64]]
  for i in 0..<int(rows):
    for j in 0..<int(dim):
      let z=v[2+i*int(dim)+j]
      if z < -1000 or z>1000 or (j<i and z!=0) or (j==i and (z<100 or z>1000)): return -1
      a[i][j]=float64(z)/1000.0
  let bytes=int(rows*dim*8)
  if outp==nil or cap<csize_t(bytes): return -2
  for k in 0..<int(rows):
    var projections: array[4,float64]
    for i in 0..<k:
      var dot,norm:float64
      for j in 0..<int(dim): dot+=a[k][j]*q[i][j]; norm+=q[i][j]*q[i][j]
      let f=dot/norm
      for j in 0..<int(dim): projections[j]+=q[i][j]*f
    for j in 0..<int(dim): q[k][j]=a[k][j]-projections[j]
  for i in 0..<int(rows):
    for j in 0..<int(dim): putF64(outp,(i*int(dim)+j)*8,q[i][j])
  int64(bytes)
