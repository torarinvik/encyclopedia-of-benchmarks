const Modulus=998244353'i64
proc log_of_set_power_series*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc.} =
  if input==nil or length<2 or length>33 or input[0]<0 or input[0]>5: return -1
  let size=1 shl int(input[0])
  if length!=csize_t(1+size) or input[1]!=1: return -1
  for i in 0 ..< size:
    if input[1+i]<0 or input[1+i]>=Modulus: return -1
  if output==nil or capacity<csize_t(8*size): return -2
  var coefficients:array[32,int64]
  for mask in 1 ..< size:
    let pivot=mask and -mask
    var sub=(mask-1) and mask; var sum=0'i64
    while sub!=0:
      if (sub and pivot)!=0: sum=(sum+coefficients[sub]*input[1+(mask xor sub)]) mod Modulus
      sub=(sub-1) and mask
    coefficients[mask]=(input[1+mask]-sum+Modulus) mod Modulus
  for i in 0 ..< size:
    let bits=uint64(coefficients[i])
    for byte in 0 ..< 8: output[8*i+byte]=uint8((bits shr (8*byte)) and 255)
  int64(8*size)
