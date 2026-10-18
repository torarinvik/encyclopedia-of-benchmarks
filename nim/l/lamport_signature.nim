const MaxInput=64
const MaxPadded=128
const K: array[64,uint32]=[
  0x428a2f98'u32,0x71374491'u32,0xb5c0fbcf'u32,0xe9b5dba5'u32,0x3956c25b'u32,0x59f111f1'u32,0x923f82a4'u32,0xab1c5ed5'u32,
  0xd807aa98'u32,0x12835b01'u32,0x243185be'u32,0x550c7dc3'u32,0x72be5d74'u32,0x80deb1fe'u32,0x9bdc06a7'u32,0xc19bf174'u32,
  0xe49b69c1'u32,0xefbe4786'u32,0x0fc19dc6'u32,0x240ca1cc'u32,0x2de92c6f'u32,0x4a7484aa'u32,0x5cb0a9dc'u32,0x76f988da'u32,
  0x983e5152'u32,0xa831c66d'u32,0xb00327c8'u32,0xbf597fc7'u32,0xc6e00bf3'u32,0xd5a79147'u32,0x06ca6351'u32,0x14292967'u32,
  0x27b70a85'u32,0x2e1b2138'u32,0x4d2c6dfc'u32,0x53380d13'u32,0x650a7354'u32,0x766a0abb'u32,0x81c2c92e'u32,0x92722c85'u32,
  0xa2bfe8a1'u32,0xa81a664b'u32,0xc24b8b70'u32,0xc76c51a3'u32,0xd192e819'u32,0xd6990624'u32,0xf40e3585'u32,0x106aa070'u32,
  0x19a4c116'u32,0x1e376c08'u32,0x2748774c'u32,0x34b0bcb5'u32,0x391c0cb3'u32,0x4ed8aa4a'u32,0x5b9cca4f'u32,0x682e6ff3'u32,
  0x748f82ee'u32,0x78a5636f'u32,0x84c87814'u32,0x8cc70208'u32,0x90befffa'u32,0xa4506ceb'u32,0xbef9a3f7'u32,0xc67178f2'u32]
proc rr(x:uint32,n:int):uint32=(x shr n) or (x shl (32-n))
proc add32(a,b:uint32):uint32=uint32((uint64(a)+uint64(b)) and 0xffff_ffff'u64)

proc lamportSha256(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 =
  if length>MaxInput or (length>0 and input.isNil):return -1
  let n=int(length)
  for i in 0..<n:if input[i]<0 or input[i]>255:return -1
  var padded:array[MaxPadded,uint8]
  for i in 0..<n:padded[i]=uint8(input[i])
  padded[n]=0x80
  let blocks=(n+9+63) div 64
  let paddedLength=blocks*64
  let bitLength=uint64(n)*8
  for i in 0..<8:padded[paddedLength-1-i]=uint8((bitLength shr (8*i)) and 255)
  var h=[0x6a09e667'u32,0xbb67ae85'u32,0x3c6ef372'u32,0xa54ff53a'u32,0x510e527f'u32,0x9b05688c'u32,0x1f83d9ab'u32,0x5be0cd19'u32]
  for blockIndex in 0..<blocks:
    var w:array[64,uint32]
    for i in 0..<16:
      let p=blockIndex*64+i*4
      w[i]=(uint32(padded[p]) shl 24) or (uint32(padded[p+1]) shl 16) or (uint32(padded[p+2]) shl 8) or uint32(padded[p+3])
    for i in 16..<64:
      let x=w[i-15];let y=w[i-2]
      let s0=rr(x,7) xor rr(x,18) xor (x shr 3);let s1=rr(y,17) xor rr(y,19) xor (y shr 10)
      w[i]=add32(add32(add32(s1,w[i-7]),s0),w[i-16])
    var a=h[0];var b=h[1];var c=h[2];var d=h[3];var e=h[4];var f=h[5];var g=h[6];var hh=h[7]
    for i in 0..<64:
      let s1=rr(e,6) xor rr(e,11) xor rr(e,25);let ch=(e and f) xor ((not e) and g)
      let t1=add32(add32(add32(add32(hh,s1),ch),K[i]),w[i])
      let s0=rr(a,2) xor rr(a,13) xor rr(a,22);let maj=(a and b) xor (a and c) xor (b and c);let t2=add32(s0,maj)
      hh=g;g=f;f=e;e=add32(d,t1);d=c;c=b;b=a;a=add32(t1,t2)
    h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh)
  if output.isNil or capacity<32:return -2
  for i in 0..<8:
    for byte in 0..<4:output[i*4+byte]=uint8((h[i] shr (24-8*byte)) and 255)
  32

const
  LamportMaxMessage = 64
  LamportDigestBits = 256
  LamportSecretBytes = 32
  LamportEntropyBytes = LamportDigestBits * 2 * LamportSecretBytes
  LamportSignatureBytes = LamportDigestBits * LamportSecretBytes
  LamportMaxParseable = 4 + 2 * LamportMaxMessage + LamportEntropyBytes + 1

proc lamportSignature*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64
    {.cdecl, exportc: "lamport_signature".} =
  if input.isNil or inputLength < csize_t(4 + LamportEntropyBytes) or inputLength > csize_t(LamportMaxParseable): return -1
  let length = int(inputLength)
  if input[0] < 0 or input[0] > LamportMaxMessage.int64: return -1
  let messageLength = int(input[0])
  let verifyLengthIndex = 1 + messageLength
  if verifyLengthIndex >= length or input[verifyLengthIndex] < 0 or input[verifyLengthIndex] > LamportMaxMessage.int64: return -1
  let verifyLength = int(input[verifyLengthIndex])
  let verifyStart = verifyLengthIndex + 1
  let verifyEnd = verifyStart + verifyLength
  if verifyEnd + 2 > length: return -1
  let tamperIndex = input[verifyEnd]
  let signTwice = input[verifyEnd + 1]
  let entropyStart = verifyEnd + 2
  if length != entropyStart + LamportEntropyBytes: return -1
  if tamperIndex < -1 or tamperIndex >= LamportSignatureBytes.int64 or signTwice < 0 or signTwice > 1: return -1
  for i in 0 ..< messageLength:
    if input[1 + i] < 0 or input[1 + i] > 255: return -1
  for i in 0 ..< verifyLength:
    if input[verifyStart + i] < 0 or input[verifyStart + i] > 255: return -1
  for i in 0 ..< LamportEntropyBytes:
    if input[entropyStart + i] < 0 or input[entropyStart + i] > 255: return -1

  var publicKey: array[LamportDigestBits, array[2, array[32, uint8]]]
  var signature: array[LamportSignatureBytes, int64]
  var messageDigest: array[32, uint8]
  for bit in 0 ..< LamportDigestBits:
    for value in 0 ..< 2:
      let secretOffset = entropyStart + (bit * 2 + value) * LamportSecretBytes
      let secretPtr = cast[ptr UncheckedArray[int64]](addr input[secretOffset])
      if lamportSha256(secretPtr, csize_t(LamportSecretBytes), cast[ptr UncheckedArray[uint8]](addr publicKey[bit][value][0]), 32) != 32: return -1
  let messagePtr = cast[ptr UncheckedArray[int64]](addr input[1])
  if lamportSha256(messagePtr, csize_t(messageLength), cast[ptr UncheckedArray[uint8]](addr messageDigest[0]), 32) != 32: return -1
  for bit in 0 ..< LamportDigestBits:
    let value = int((messageDigest[bit div 8] shr (7 - (bit mod 8))) and 1'u8)
    let secretOffset = entropyStart + (bit * 2 + value) * LamportSecretBytes
    for byte in 0 ..< LamportSecretBytes:
      signature[bit * LamportSecretBytes + byte] = input[secretOffset + byte]
  if signTwice == 1: return -1

  if tamperIndex >= 0: signature[int(tamperIndex)] = signature[int(tamperIndex)] xor 1
  var verifyDigest: array[32, uint8]
  let verifyPtr = cast[ptr UncheckedArray[int64]](addr input[verifyStart])
  if lamportSha256(verifyPtr, csize_t(verifyLength), cast[ptr UncheckedArray[uint8]](addr verifyDigest[0]), 32) != 32: return -1
  var verified = 1'u8
  for bit in 0 ..< LamportDigestBits:
    let value = int((verifyDigest[bit div 8] shr (7 - (bit mod 8))) and 1'u8)
    var actualHash: array[32, uint8]
    let signaturePtr = cast[ptr UncheckedArray[int64]](addr signature[bit * LamportSecretBytes])
    if lamportSha256(signaturePtr, csize_t(LamportSecretBytes), cast[ptr UncheckedArray[uint8]](addr actualHash[0]), 32) != 32: return -1
    for byte in 0 ..< 32:
      if actualHash[byte] != publicKey[bit][value][byte]:
        verified = 0
        break
    if verified == 0: break
  if tamperIndex >= 0: signature[int(tamperIndex)] = signature[int(tamperIndex)] xor 1

  var fingerprint = 0xcbf29ce484222325'u64
  for bit in 0 ..< LamportDigestBits:
    for value in 0 ..< 2:
      for byte in 0 ..< 32:
        fingerprint = (fingerprint xor uint64(publicKey[bit][value][byte])) * 0x100000001b3'u64
  for i in 0 ..< LamportSignatureBytes:
    fingerprint = (fingerprint xor uint64(signature[i] and 255)) * 0x100000001b3'u64
  fingerprint = (fingerprint xor uint64(verified)) * 0x100000001b3'u64
  int64(fingerprint and 0x7fffffffffffffff'u64)
