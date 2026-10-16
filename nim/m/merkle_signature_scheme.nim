const MaxInput=8192
const MaxPadded=8256
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

proc sha256*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"sha256".}=
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

const Hex="0123456789abcdef"

proc verifySignature(input: ptr UncheckedArray[int64], height, w, msg, leafIndex, sigPos, pkPos, authPos, rootPos, l: int): int64 =
  var digest: array[32,uint8]; var current: array[32,uint8]
  if sha256(addr input[3],csize_t(msg),addr digest[0],32)!=32:return 0
  let logW=if w==4:2 elif w==16:4 else:8
  let len1=if w==4:128 elif w==16:64 else:32
  let len2=l-len1;let mask=w-1
  var digits: array[133,uint8];var d=0;var checksum=0
  for byte in 0..<32:
    for part in 0..<(8 div logW):
      let shift=8-logW*(part+1)
      digits[d]=uint8((int(digest[byte]) shr shift) and mask)
      checksum += mask-int(digits[d]);inc d
  for i in 0..<len2:
    digits[len1+len2-1-i]=uint8(checksum and mask);checksum=checksum shr logW
  var chain: array[32,int64]
  for i in 0..<l:
    for j in 0..<32:chain[j]=input[sigPos+32*i+j]
    for step in 0..<(w-1-int(digits[i])):
      if sha256(addr chain[0],32,addr current[0],32)!=32:return 0
      for j in 0..<32:chain[j]=int64(current[j])
    for j in 0..<32:
      if uint8(chain[j])!=uint8(input[pkPos+32*i+j]):return 0
  if sha256(addr input[pkPos],csize_t(32*l),addr digest[0],32)!=32:return 0
  var pair: array[64,int64];var index=leafIndex
  for level in 0..<height:
    for j in 0..<32:
      let left=int64(digest[j]);let right=input[authPos+32*level+j]
      if index mod 2 == 0:
        pair[j]=left
        pair[32+j]=right
      else:
        pair[j]=right
        pair[32+j]=left
    if sha256(addr pair[0],64,addr digest[0],32)!=32:return 0
    index=index shr 1
  for j in 0..<32:
    if int64(digest[j])!=input[rootPos+j]:return 0
  1

proc merkle_signature_scheme*(input: ptr UncheckedArray[int64], length:csize_t, output:ptr UncheckedArray[uint8], capacity:csize_t):int64 {.cdecl,exportc:"merkle_signature_scheme".}=
  if input.isNil or length<4 or length>8932:return -1
  let h0=input[0];let w0=input[1];let m0=input[2]
  if h0<2 or h0>10 or (w0!=4 and w0!=16 and w0!=256) or m0<0 or m0>64:return -1
  let height=int(h0);let w=int(w0);let msg=int(m0);let l=if w==4:133 elif w==16:67 else:34
  let ip=3+msg;let expected=4+msg+64*l+32*height+32
  if int(length)!=expected:return -1
  for i in 0..<msg:if input[3+i]<0 or input[3+i]>127:return -1
  let idx=input[ip];if idx<0 or uint64(idx)>=(1'u64 shl height):return -1
  let sig=ip+1;let pk=sig+32*l;let auth=pk+32*l;let root=auth+32*height
  for i in sig..<int(length):if input[i]<0 or input[i]>255:return -1
  if output.isNil or capacity<8:return -2
  let valid=verifySignature(input,height,w,msg,int(idx),sig,pk,auth,root,l)
  for i in 0..<8:output[i]=0
  output[0]=uint8(valid);8
