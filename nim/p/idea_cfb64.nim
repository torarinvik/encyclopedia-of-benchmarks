proc mul16(a,b:uint16):uint16 =
  let x=if a==0:65536'u64 else:uint64(a);let y=if b==0:65536'u64 else:uint64(b);let z=(x*y) mod 65537'u64
  if z==65536:0'u16 else:uint16(z)
proc add16(a,b:uint16):uint16 = uint16((uint32(a)+uint32(b)) and 65535'u32)
proc expand(key:array[16,uint8]):array[52,uint16] =
  var state:array[8,uint16]
  for i in 0..<8:state[i]=(uint16(key[2*i]) shl 8) or uint16(key[2*i+1])
  var off=0
  while off<52:
    let take=min(8,52-off)
    for i in 0..<take:result[off+i]=state[i]
    var rotated:array[8,uint16]
    for i in 0..<8:rotated[i]=uint16((uint32(state[(i+1) and 7]) shl 9) or (uint32(state[(i+2) and 7]) shr 7))
    state=rotated;off+=8
proc encrypt(z:array[52,uint16],block:array[8,uint8]):array[8,uint8] =
  var x1=(uint16(block[0]) shl 8) or uint16(block[1]);var x2=(uint16(block[2]) shl 8) or uint16(block[3]);var x3=(uint16(block[4]) shl 8) or uint16(block[5]);var x4=(uint16(block[6]) shl 8) or uint16(block[7])
  for r in 0..<8:
    let k=r*6;let a=mul16(x1,z[k]);let b=add16(x2,z[k+1]);let c=add16(x3,z[k+2]);let d=mul16(x4,z[k+3]);let p=mul16(a xor c,z[k+4]);let q=mul16(add16(b xor d,p),z[k+5]);let t=add16(p,q);x1=a xor q;x2=c xor q;x3=b xor t;x4=d xor t
  let words=[mul16(x1,z[48]),add16(x3,z[49]),add16(x2,z[50]),mul16(x4,z[51])]
  for i in 0..<4:result[2*i]=uint8(words[i] shr 8);result[2*i+1]=uint8(words[i] and 255)
proc put(outp:ptr UncheckedArray[byte],data:array[24,uint8],n:int)=
  for i in 0..<n:outp[i]=byte(data[i])
proc idea_cfb64*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[byte],capacity:csize_t):int64 {.cdecl,exportc:"idea_cfb64".}=
  if values==nil or length<27 or length>51:return -1
  let mode=values[0];let rawLen=values[1];if mode<0 or mode>1 or rawLen<1 or rawLen>24 or int(length)!=26+int(rawLen):return -1
  let textLen=int(rawLen);var key:array[16,uint8];var state:array[8,uint8];var text:array[24,uint8];var result:array[24,uint8]
  for i in 0..<16:if values[2+i]<0 or values[2+i]>255:return -1 else:key[i]=uint8(values[2+i])
  for i in 0..<8:if values[18+i]<0 or values[18+i]>255:return -1 else:state[i]=uint8(values[18+i])
  for i in 0..<textLen:if values[26+i]<0 or values[26+i]>255:return -1 else:text[i]=uint8(values[26+i])
  let subkeys=expand(key);var pos=0
  while pos<textLen:
    let stream=encrypt(subkeys,state);let take=min(8,textLen-pos)
    for j in 0..<take:
      result[pos+j]=text[pos+j] xor stream[j]
      if mode==0: state[j]=result[pos+j] else: state[j]=text[pos+j]
    pos+=take
  if output==nil or capacity<csize_t(textLen):return -2
  put(output,result,textLen);int64(textLen)
