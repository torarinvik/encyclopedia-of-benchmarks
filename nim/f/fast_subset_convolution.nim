const Modulus = 998_244_353'i64

proc rankOf(mask: int): int =
  var bits = mask
  while bits > 0:
    result += bits and 1
    bits = bits shr 1
proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (8*b)) and 255'u64)

proc fast_subset_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "fast_subset_convolution".} =
  if input.isNil or length<3 or length>33: return -1
  let n64=input[0]
  if n64<0 or n64>4: return -1
  let n=int(n64);let size=1 shl n
  if length!=csize_t(1+2*size):return -1
  for i in 0..<(2*size):
    if input[1+i]<0 or input[1+i]>=Modulus:return -1
  var f: array[5,array[16,int64]]
  var g: array[5,array[16,int64]]
  var h: array[5,array[16,int64]]
  for s in 0..<size:
    let r=rankOf(s);f[r][s]=input[1+s];g[r][s]=input[1+size+s]
  for bit in 0..<n:
    for s in 0..<size:
      if (s and (1 shl bit))!=0:
        let other=s xor (1 shl bit)
        for r in 0..n:
          f[r][s]=(f[r][s]+f[r][other]) mod Modulus
          g[r][s]=(g[r][s]+g[r][other]) mod Modulus
  for s in 0..<size:
    for r in 0..n:
      var sum=0'i64
      for i in 0..r: sum=(sum+f[i][s]*g[r-i][s]) mod Modulus
      h[r][s]=sum
  for bit in 0..<n:
    for s in 0..<size:
      if (s and (1 shl bit))!=0:
        let other=s xor (1 shl bit)
        for r in 0..n: h[r][s]=(h[r][s]-h[r][other]+Modulus) mod Modulus
  let required=size*8
  if capacity<csize_t(required) or output.isNil:return -2
  for s in 0..<size:putI64Le(output,8*s,h[rankOf(s)][s])
  int64(required)
