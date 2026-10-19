type U8Array = ptr UncheckedArray[uint8]
const IP: array[64, uint8] = [58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4,62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8,57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3,61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7]
const IP_INV: array[64, uint8] = [40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31,38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29,36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27,34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25]
const E: array[48, uint8] = [32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13,12,13,14,15,16,17,16,17,18,19,20,21,20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1]
const P: array[32, uint8] = [16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10,2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25]
const PC1: array[56, uint8] = [57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,27,19,11,3,60,52,44,36,63,55,47,39,31,23,15,7,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,28,20,12,4]
const PC2: array[48, uint8] = [14,17,11,24,1,5,3,28,15,6,21,10,23,19,12,4,26,8,16,7,27,20,13,2,41,52,31,37,47,55,30,40,51,45,33,48,44,49,39,56,34,53,46,42,50,36,29,32]
const SHIFTS: array[16, uint8] = [1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1]
const SBOX: array[8, array[4, array[16, uint8]]] = [[[14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7],[0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8],[4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0],[15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13]],[[15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10],[3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5],[0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15],[13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9]],[[10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8],[13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1],[13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7],[1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12]],[[7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15],[13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9],[10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4],[3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14]],[[2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9],[14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6],[4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14],[11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3]],[[12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11],[10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8],[9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6],[4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13]],[[4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1],[13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6],[1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2],[6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12]],[[13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7],[1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2],[7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8],[2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11]]]
proc permute(v:uint64, table: openArray[uint8], width:uint32):uint64 =
  var acc:uint64=0
  for p in table: acc=(acc shl 1) or ((v shr (width-uint32(p))) and 1)
  acc
proc makeKeys(key:uint64):array[16,uint64] =
  let mask=(1'u64 shl 28)-1
  let t=permute(key,PC1,64)
  var left=t shr 28; var right=t and mask
  for i in 0..<16:
    let sh=uint32(SHIFTS[i]); left=((left shl sh) or (left shr (28-sh))) and mask; right=((right shl sh) or (right shr (28-sh))) and mask
    result[i]=permute((left shl 28) or right,PC2,56)
proc feistel(r:uint32,key:uint64):uint32 =
  let x=permute(uint64(r),E,32) xor key
  var s:uint32=0
  for i in 0..<8:
    let six=int((x shr uint32(42-6*i)) and 63); let row=((six and 32) shr 4) or (six and 1); let col=(six shr 1) and 15
    s=(s shl 4) or uint32(SBOX[i][row][col])
  uint32(permute(uint64(s),P,32))
proc encrypt(b:uint64, keys:array[16,uint64]):uint64 =
  let state=permute(b,IP,64)
  var left=uint32(state shr 32); var right=uint32(state and 0xffffffff'u64)
  for k in keys:
    let next=left xor feistel(right,k); left=right; right=next
  permute((uint64(right) shl 32) or uint64(left),IP_INV,64)

proc feistelSalt(r:uint32,key:uint64,salt:uint16):uint32 =
  var expansion=E
  for i in 0..<12:
    if ((salt shr i) and 1)!=0: swap(expansion[i],expansion[i+24])
  let x=permute(uint64(r),expansion,32) xor key
  var s:uint32=0
  for i in 0..<8:
    let six=int((x shr uint32(42-6*i)) and 63);let row=((six and 32) shr 4) or (six and 1);let col=(six shr 1) and 15
    s=(s shl 4) or uint32(SBOX[i][row][col])
  uint32(permute(uint64(s),P,32))
proc encryptSalt(b:uint64,keys:array[16,uint64],salt:uint16):uint64 =
  let state=permute(b,IP,64);var left=uint32(state shr 32);var right=uint32(state and 0xffffffff'u64)
  for k in keys:
    let next=left xor feistelSalt(right,k,salt);left=right;right=next
  permute((uint64(right) shl 32) or uint64(left),IP_INV,64)
const candidates=" !\"$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}"
const cryptAlphabet="./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
proc allowed(c:uint8):bool =
  for x in candidates:
    if uint8(ord(x))==c:return true
  false
proc cryptCode(c:uint8):int =
  if c==uint8(ord('@')):return 11
  for i,x in cryptAlphabet:
    if uint8(ord(x))==c:return i
  -1
proc normSalt(c0:uint8):uint8 =
  var c=c0
  if c<uint8(ord('.')) or c>uint8(ord('z')):c=uint8(ord('.'))
  if (c>=uint8(ord(':')) and c<=uint8(ord('@'))) or (c>=uint8(ord('[')) and c<=uint8(ord('`'))):c+=6
  c
proc tripforce_tripcode*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tripforce_tripcode".} =
  if input==nil or length!=8:return -1
  var password:array[8,uint8]
  for i in 0..<8:
    if input[i]<0 or input[i]>127 or not allowed(uint8(input[i])):return -1
    password[i]=uint8(input[i])
  if output==nil or capacity<10:return -2
  let a=cryptCode(normSalt(password[1]));let b=cryptCode(normSalt(password[2]));if a<0 or b<0:return -1
  let salt=uint16(a or (b shl 6));var key:uint64=0
  for c in password:key=(key shl 8) or uint64((c shl 1) and 255)
  let keys=makeKeys(key);var block:uint64=0
  for _ in 0..<25:block=encryptSalt(block,keys,salt)
  var raw:array[8,uint8]
  for i in 0..<4:raw[i]=uint8((block shr (32+8*i)) and 255);raw[i+4]=uint8((block shr (8*i)) and 255)
  var encoded:array[11,uint8]
  for g in 0..<11:
    var v=0
    for j in 0..<6:
      let bit=g*6+j;v=v shl 1
      if bit<64:v=v or int((raw[bit div 8] shr (7-(bit mod 8))) and 1)
    encoded[g]=uint8(ord(cryptAlphabet[v]))
  for i in 0..<10:output[i]=encoded[i+1]
  10
