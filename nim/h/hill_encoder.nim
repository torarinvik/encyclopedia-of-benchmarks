proc hill_encoder*(v: ptr UncheckedArray[int64], n: csize_t, outp: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "hill_encoder".} =
  if v.isNil or n < 10 or n > 74: return -1
  if v[0] < 0 or v[0] > 64 or n != csize_t(10 + v[0]): return -1
  let length=int(v[0]);let padded=(length+2) div 3*3
  var text,key,transformed: array[66,int64]
  for i in 0 ..< length:
    if v[1+i] < 65 or v[1+i] > 90: return -1
    text[i]=v[1+i]
  for i in length ..< padded: text[i]=32
  for i in 0 ..< 9:
    let x=v[1+length+i]
    if x < -2 or x > 2: return -1
    key[i]=x
  if padded > 0:
    for off in countup(0,padded-1,3):
      for row in 0 ..< 3:
        var sum:int64=0
        for col in 0 ..< 3: sum += key[row*3+col]*text[off+col]
        if sum < 0 or sum > 65535: return -1
        transformed[off+row]=sum
  let bytes=padded*8
  if outp.isNil or cap < csize_t(bytes): return -2
  for i in 0 ..< padded:
    let bits=cast[uint64](transformed[i])
    for k in 0 ..< 8: outp[i*8+k]=uint8((bits shr (8*k)) and 255)
  int64(bytes)
