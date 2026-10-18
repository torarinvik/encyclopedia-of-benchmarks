const MaxMessageBytes = 4096
const MaxParseableInputLength = 4099
const MaxPaddedBytes = 4224
const MaxOutputBytes = 64
const K32: array[64, uint32] = [
  0x428a2f98'u32,0x71374491'u32,0xb5c0fbcf'u32,0xe9b5dba5'u32,0x3956c25b'u32,0x59f111f1'u32,0x923f82a4'u32,0xab1c5ed5'u32,
  0xd807aa98'u32,0x12835b01'u32,0x243185be'u32,0x550c7dc3'u32,0x72be5d74'u32,0x80deb1fe'u32,0x9bdc06a7'u32,0xc19bf174'u32,
  0xe49b69c1'u32,0xefbe4786'u32,0x0fc19dc6'u32,0x240ca1cc'u32,0x2de92c6f'u32,0x4a7484aa'u32,0x5cb0a9dc'u32,0x76f988da'u32,
  0x983e5152'u32,0xa831c66d'u32,0xb00327c8'u32,0xbf597fc7'u32,0xc6e00bf3'u32,0xd5a79147'u32,0x06ca6351'u32,0x14292967'u32,
  0x27b70a85'u32,0x2e1b2138'u32,0x4d2c6dfc'u32,0x53380d13'u32,0x650a7354'u32,0x766a0abb'u32,0x81c2c92e'u32,0x92722c85'u32,
  0xa2bfe8a1'u32,0xa81a664b'u32,0xc24b8b70'u32,0xc76c51a3'u32,0xd192e819'u32,0xd6990624'u32,0xf40e3585'u32,0x106aa070'u32,
  0x19a4c116'u32,0x1e376c08'u32,0x2748774c'u32,0x34b0bcb5'u32,0x391c0cb3'u32,0x4ed8aa4a'u32,0x5b9cca4f'u32,0x682e6ff3'u32,
  0x748f82ee'u32,0x78a5636f'u32,0x84c87814'u32,0x8cc70208'u32,0x90befffa'u32,0xa4506ceb'u32,0xbef9a3f7'u32,0xc67178f2'u32]
const K64: array[80, uint64] = [
  0x428a2f98d728ae22'u64,0x7137449123ef65cd'u64,0xb5c0fbcfec4d3b2f'u64,0xe9b5dba58189dbbc'u64,
  0x3956c25bf348b538'u64,0x59f111f1b605d019'u64,0x923f82a4af194f9b'u64,0xab1c5ed5da6d8118'u64,
  0xd807aa98a3030242'u64,0x12835b0145706fbe'u64,0x243185be4ee4b28c'u64,0x550c7dc3d5ffb4e2'u64,
  0x72be5d74f27b896f'u64,0x80deb1fe3b1696b1'u64,0x9bdc06a725c71235'u64,0xc19bf174cf692694'u64,
  0xe49b69c19ef14ad2'u64,0xefbe4786384f25e3'u64,0x0fc19dc68b8cd5b5'u64,0x240ca1cc77ac9c65'u64,
  0x2de92c6f592b0275'u64,0x4a7484aa6ea6e483'u64,0x5cb0a9dcbd41fbd4'u64,0x76f988da831153b5'u64,
  0x983e5152ee66dfab'u64,0xa831c66d2db43210'u64,0xb00327c898fb213f'u64,0xbf597fc7beef0ee4'u64,
  0xc6e00bf33da88fc2'u64,0xd5a79147930aa725'u64,0x06ca6351e003826f'u64,0x142929670a0e6e70'u64,
  0x27b70a8546d22ffc'u64,0x2e1b21385c26c926'u64,0x4d2c6dfc5ac42aed'u64,0x53380d139d95b3df'u64,
  0x650a73548baf63de'u64,0x766a0abb3c77b2a8'u64,0x81c2c92e47edaee6'u64,0x92722c851482353b'u64,
  0xa2bfe8a14cf10364'u64,0xa81a664bbc423001'u64,0xc24b8b70d0f89791'u64,0xc76c51a30654be30'u64,
  0xd192e819d6ef5218'u64,0xd69906245565a910'u64,0xf40e35855771202a'u64,0x106aa07032bbd1b8'u64,
  0x19a4c116b8d2d0c8'u64,0x1e376c085141ab53'u64,0x2748774cdf8eeb99'u64,0x34b0bcb5e19b48a8'u64,
  0x391c0cb3c5c95a63'u64,0x4ed8aa4ae3418acb'u64,0x5b9cca4f7763e373'u64,0x682e6ff3d6b2b8a3'u64,
  0x748f82ee5defb2fc'u64,0x78a5636f43172f60'u64,0x84c87814a1f0ab72'u64,0x8cc702081a6439ec'u64,
  0x90befffa23631e28'u64,0xa4506cebde82bde9'u64,0xbef9a3f7b2c67915'u64,0xc67178f2e372532b'u64,
  0xca273eceea26619c'u64,0xd186b8c721c0c207'u64,0xeada7dd6cde0eb1e'u64,0xf57d4f7fee6ed178'u64,
  0x06f067aa72176fba'u64,0x0a637dc5a2c898a6'u64,0x113f9804bef90dae'u64,0x1b710b35131c471b'u64,
  0x28db77f523047d84'u64,0x32caab7b40c72493'u64,0x3c9ebe0a15c9bebc'u64,0x431d67c49c100d4c'u64,
  0x4cc5d4becb3e42b6'u64,0x597f299cfc657e2a'u64,0x5fcb6fab3ad6faec'u64,0x6c44198c4a475817'u64]
const H224: array[8, uint32] = [0xc1059ed8'u32,0x367cd507'u32,0x3070dd17'u32,0xf70e5939'u32,0xffc00b31'u32,0x68581511'u32,0x64f98fa7'u32,0xbefa4fa4'u32]
const H256: array[8, uint32] = [0x6a09e667'u32,0xbb67ae85'u32,0x3c6ef372'u32,0xa54ff53a'u32,0x510e527f'u32,0x9b05688c'u32,0x1f83d9ab'u32,0x5be0cd19'u32]
const H384: array[8, uint64] = [0xcbbb9d5dc1059ed8'u64,0x629a292a367cd507'u64,0x9159015a3070dd17'u64,0x152fecd8f70e5939'u64,0x67332667ffc00b31'u64,0x8eb44a8768581511'u64,0xdb0c2e0d64f98fa7'u64,0x47b5481dbefa4fa4'u64]
const H512: array[8, uint64] = [0x6a09e667f3bcc908'u64,0xbb67ae8584caa73b'u64,0x3c6ef372fe94f82b'u64,0xa54ff53a5f1d36f1'u64,0x510e527fade682d1'u64,0x9b05688c2b3e6c1f'u64,0x1f83d9abfb41bd6b'u64,0x5be0cd19137e2179'u64]
const H512_224: array[8, uint64] = [0x8c3d37c819544da2'u64,0x73e1996689dcd4d6'u64,0x1dfab7ae32ff9c82'u64,0x679dd514582f9fcf'u64,0x0f6d2b697bd44da8'u64,0x77e36f7304c48942'u64,0x3f9d85a86a1d36c8'u64,0x1112e6ad91d692a1'u64]
const H512_256: array[8, uint64] = [0x22312194fc2bf72c'u64,0x9f555fa3c84c64c2'u64,0x2393b86b6f53b151'u64,0x963877195940eabd'u64,0x96283ee2a88effe3'u64,0xbe5e1e2553863992'u64,0x2b0199fc2c85b8aa'u64,0x0eb72ddc81c52ca2'u64]

proc rotr32(value: uint32, amount: int): uint32 = (value shr amount) or (value shl (32 - amount))
proc rotr64(value: uint64, amount: int): uint64 = (value shr amount) or (value shl (64 - amount))

proc compress32(state: var array[8, uint32], blockBytes: openArray[uint8]) =
  var words: array[64, uint32]
  for index in 0 ..< 16:
    let offset = index * 4
    words[index] = (uint32(blockBytes[offset]) shl 24) or (uint32(blockBytes[offset + 1]) shl 16) or
      (uint32(blockBytes[offset + 2]) shl 8) or uint32(blockBytes[offset + 3])
  for index in 16 ..< 64:
    let x = words[index - 15]; let y = words[index - 2]
    let s0 = rotr32(x, 7) xor rotr32(x, 18) xor (x shr 3)
    let s1 = rotr32(y, 17) xor rotr32(y, 19) xor (y shr 10)
    words[index] = words[index - 16] + s0 + words[index - 7] + s1
  var a=state[0];var b=state[1];var c=state[2];var d=state[3];var e=state[4];var f=state[5];var g=state[6];var h=state[7]
  for index in 0 ..< 64:
    let sigma1=rotr32(e,6) xor rotr32(e,11) xor rotr32(e,25)
    let choose=(e and f) xor ((not e) and g)
    let temp1=h+sigma1+choose+K32[index]+words[index]
    let sigma0=rotr32(a,2) xor rotr32(a,13) xor rotr32(a,22)
    let majority=(a and b) xor (a and c) xor (b and c)
    let temp2=sigma0+majority
    h=g;g=f;f=e;e=d+temp1;d=c;c=b;b=a;a=temp1+temp2
  state[0]+=a;state[1]+=b;state[2]+=c;state[3]+=d;state[4]+=e;state[5]+=f;state[6]+=g;state[7]+=h

proc compress64(state: var array[8, uint64], blockBytes: openArray[uint8]) =
  var words: array[80, uint64]
  for index in 0 ..< 16:
    var value = 0'u64
    for byte in 0 ..< 8: value = (value shl 8) or uint64(blockBytes[index * 8 + byte])
    words[index] = value
  for index in 16 ..< 80:
    let x=words[index-15];let y=words[index-2]
    let s0=rotr64(x,1) xor rotr64(x,8) xor (x shr 7)
    let s1=rotr64(y,19) xor rotr64(y,61) xor (y shr 6)
    words[index]=words[index-16]+s0+words[index-7]+s1
  var a=state[0];var b=state[1];var c=state[2];var d=state[3];var e=state[4];var f=state[5];var g=state[6];var h=state[7]
  for index in 0 ..< 80:
    let sigma1=rotr64(e,14) xor rotr64(e,18) xor rotr64(e,41)
    let choose=(e and f) xor ((not e) and g)
    let temp1=h+sigma1+choose+K64[index]+words[index]
    let sigma0=rotr64(a,28) xor rotr64(a,34) xor rotr64(a,39)
    let majority=(a and b) xor (a and c) xor (b and c)
    let temp2=sigma0+majority
    h=g;g=f;f=e;e=d+temp1;d=c;c=b;b=a;a=temp1+temp2
  state[0]+=a;state[1]+=b;state[2]+=c;state[3]+=d;state[4]+=e;state[5]+=f;state[6]+=g;state[7]+=h

proc sha2Digest(variant: int, input: ptr UncheckedArray[int64], messageLength: int): array[64, uint8] =
  let digestLengths = [28, 32, 48, 64, 28, 32]
  var padded: array[MaxPaddedBytes, uint8]
  for index in 0 ..< messageLength: padded[index] = uint8(input[2 + index])
  padded[messageLength] = 0x80
  var digest: array[64, uint8]
  if variant < 2:
    var paddedLength = messageLength + 1
    while paddedLength mod 64 != 56: inc paddedLength
    paddedLength += 8
    let bitLength = uint64(messageLength) * 8
    for byte in 0 ..< 8: padded[paddedLength - 1 - byte] = uint8((bitLength shr (8 * byte)) and 255)
    var state = if variant == 0: H224 else: H256
    for offset in countup(0, paddedLength - 64, 64): compress32(state, padded.toOpenArray(offset, offset + 63))
    for word in 0 ..< 8:
      for byte in 0 ..< 4:
        let outIndex = word * 4 + byte
        if outIndex < digestLengths[variant]: digest[outIndex] = uint8((state[word] shr (24 - 8 * byte)) and 255)
  else:
    var paddedLength = messageLength + 1
    while paddedLength mod 128 != 112: inc paddedLength
    paddedLength += 16
    let bitLength = uint64(messageLength) * 8
    for byte in 0 ..< 8: padded[paddedLength - 1 - byte] = uint8((bitLength shr (8 * byte)) and 255)
    var state = case variant
      of 2: H384
      of 3: H512
      of 4: H512_224
      else: H512_256
    for offset in countup(0, paddedLength - 128, 128): compress64(state, padded.toOpenArray(offset, offset + 127))
    for word in 0 ..< 8:
      for byte in 0 ..< 8:
        let outIndex = word * 8 + byte
        if outIndex < digestLengths[variant]: digest[outIndex] = uint8((state[word] shr (56 - 8 * byte)) and 255)
  digest

proc sha2*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sha2".} =
  if input.isNil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > 5 or input[1] < 0 or input[1] > MaxMessageBytes: return -1
  let variant = int(input[0]); let messageLength = int(input[1])
  if int(inputLength) != 2 + messageLength: return -1
  for index in 0 ..< messageLength:
    if input[2 + index] < 0 or input[2 + index] > 255: return -1
  let digestLengths = [28,32,48,64,28,32]
  let digestLength = digestLengths[variant]
  if digestLength > MaxOutputBytes: return -1
  if output.isNil or outputCapacity < digestLength.csize_t: return -2
  let digest = sha2Digest(variant, input, messageLength)
  for index in 0 ..< digestLength: output[index] = digest[index]
  digestLength.int64
