const MaxInput = 4096
const MaxPadded = 4160

proc rol(value: uint32, shift: int): uint32 = (value shl shift) or (value shr (32 - shift))
proc add32(left, right: uint32): uint32 = uint32((uint64(left) + uint64(right)) and 0xFFFF_FFFF'u64)

proc sha1*(input: ptr UncheckedArray[int64], length: csize_t,
          output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "sha1".} =
  if length > MaxInput or (length > 0 and input.isNil): return -1
  let n = int(length)
  for i in 0 ..< n:
    if input[i] < 0 or input[i] > 255: return -1
  var padded: array[MaxPadded, uint8]
  for i in 0 ..< n: padded[i] = uint8(input[i])
  padded[n] = 0x80
  let blocks = (n + 9 + 63) div 64
  let paddedLength = blocks * 64
  let bitLength = uint64(n) * 8
  for i in 0 ..< 8: padded[paddedLength - 1 - i] = uint8((bitLength shr (8 * i)) and 255)
  var h0=0x67452301'u32; var h1=0xEFCDAB89'u32; var h2=0x98BADCFE'u32
  var h3=0x10325476'u32; var h4=0xC3D2E1F0'u32
  for blockIndex in 0 ..< blocks:
    var w: array[80, uint32]
    for i in 0 ..< 16:
      let p=blockIndex*64+i*4
      w[i]=(uint32(padded[p]) shl 24) or (uint32(padded[p+1]) shl 16) or
           (uint32(padded[p+2]) shl 8) or uint32(padded[p+3])
    for i in 16 ..< 80: w[i]=rol(w[i-3] xor w[i-8] xor w[i-14] xor w[i-16],1)
    var a=h0; var b=h1; var c=h2; var d=h3; var e=h4
    for i in 0 ..< 80:
      var f,k: uint32
      if i < 20: f=(b and c) or ((not b) and d); k=0x5A827999'u32
      elif i < 40: f=b xor c xor d; k=0x6ED9EBA1'u32
      elif i < 60: f=(b and c) or (b and d) or (c and d); k=0x8F1BBCDC'u32
      else: f=b xor c xor d; k=0xCA62C1D6'u32
      let temp=add32(add32(add32(add32(rol(a,5),f),e),k),w[i])
      e=d; d=c; c=rol(b,30); b=a; a=temp
    h0=add32(h0,a); h1=add32(h1,b); h2=add32(h2,c); h3=add32(h3,d); h4=add32(h4,e)
  if output.isNil or capacity < 20: return -2
  let digest=[h0,h1,h2,h3,h4]
  for i in 0 ..< 5:
    for byte in 0 ..< 4: output[i*4+byte]=uint8((digest[i] shr (24-8*byte)) and 255)
  20
