proc xtea*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"xtea".}=
 if input==nil or length!=25:return -1
 if input[0]<1 or input[0]>64:return -1
 for i in 1..<25:if input[i]<0 or input[i]>255:return -1
 if output==nil or capacity<8:return -2
 var v0=0'u32;var v1=0'u32;var k:array[4,uint32]
 for i in 0..<4:
  v0=(v0 shl 8) or uint32(input[1+i]);v1=(v1 shl 8) or uint32(input[5+i])
  for j in 0..<4:k[i]=(k[i] shl 8) or uint32(input[9+i*4+j])
 var sum=0'u32
 for r in 0..<int(input[0]):
  v0=v0+%((((v1 shl 4 xor v1 shr 5)+%v1) xor (sum+%k[int(sum and 3)])))
  sum=sum+%0x9E3779B9'u32
  v1=v1+%((((v0 shl 4 xor v0 shr 5)+%v0) xor (sum+%k[int((sum shr 11) and 3)])))
 for i in 0..<4:output[i]=uint8(v0 shr (24-8*i));output[4+i]=uint8(v1 shr (24-8*i))
 8
