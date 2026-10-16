proc fifocache*(a: ptr UncheckedArray[int64], n: csize_t, o: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "fifocache".} =
  if a.isNil or n < 2 or n > 26: return -1
  let c=a[0]; let ops=a[1]
  if c < 1 or c > 6 or ops < 0 or ops > 8 or n != 2+3*csize_t(ops): return -1
  var k: array[6,int64]; var v: array[6,int64]; var q: array[8,uint8]
  var z=0; var g=0; var h=0'u8; var m=0'u8
  for i in 0..<int(ops):
    let op=a[2+3*i]; let key=a[3+3*i]; let value=a[4+3*i]
    if key < 0 or key > 15 or (op != 0 and op != 1): return -1
    if op == 0:
      if value < 0 or value > 255: return -1
      var j=0; while j<z and k[j]!=key: inc j
      if j<z:
        for t in j+1..<z: k[t-1]=k[t]; v[t-1]=v[t]
        dec z
      if z==int(c):
        for t in 1..<z: k[t-1]=k[t]; v[t-1]=v[t]
        dec z
      k[z]=key; v[z]=value; inc z
    else:
      if value != 0: return -1
      var j=0; while j<z and k[j]!=key: inc j
      if j<z: inc h; q[g]=uint8(v[j])
      else: inc m; q[g]=255'u8
      inc g
  let need=4+g+2*z
  if o.isNil or cap<csize_t(need): return -2
  o[0]=h; o[1]=m; o[2]=uint8(z); o[3]=uint8(g)
  for i in 0..<g: o[4+i]=q[i]
  for i in 0..<z: o[4+g+2*i]=uint8(k[i]); o[5+g+2*i]=uint8(v[i])
  int64(need)
