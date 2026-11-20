const MaxWords = 35
const MaxPayload = 32
const MaxBase58 = 51
const Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
const ShaK: array[64, uint32] = [
  0x428a2f98'u32,0x71374491'u32,0xb5c0fbcf'u32,0xe9b5dba5'u32,0x3956c25b'u32,0x59f111f1'u32,0x923f82a4'u32,0xab1c5ed5'u32,
  0xd807aa98'u32,0x12835b01'u32,0x243185be'u32,0x550c7dc3'u32,0x72be5d74'u32,0x80deb1fe'u32,0x9bdc06a7'u32,0xc19bf174'u32,
  0xe49b69c1'u32,0xefbe4786'u32,0x0fc19dc6'u32,0x240ca1cc'u32,0x2de92c6f'u32,0x4a7484aa'u32,0x5cb0a9dc'u32,0x76f988da'u32,
  0x983e5152'u32,0xa831c66d'u32,0xb00327c8'u32,0xbf597fc7'u32,0xc6e00bf3'u32,0xd5a79147'u32,0x06ca6351'u32,0x14292967'u32,
  0x27b70a85'u32,0x2e1b2138'u32,0x4d2c6dfc'u32,0x53380d13'u32,0x650a7354'u32,0x766a0abb'u32,0x81c2c92e'u32,0x92722c85'u32,
  0xa2bfe8a1'u32,0xa81a664b'u32,0xc24b8b70'u32,0xc76c51a3'u32,0xd192e819'u32,0xd6990624'u32,0xf40e3585'u32,0x106aa070'u32,
  0x19a4c116'u32,0x1e376c08'u32,0x2748774c'u32,0x34b0bcb5'u32,0x391c0cb3'u32,0x4ed8aa4a'u32,0x5b9cca4f'u32,0x682e6ff3'u32,
  0x748f82ee'u32,0x78a5636f'u32,0x84c87814'u32,0x8cc70208'u32,0x90befffa'u32,0xa4506ceb'u32,0xbef9a3f7'u32,0xc67178f2'u32]

proc shaAdd(a, b: uint32): uint32 = uint32((uint64(a) + uint64(b)) and 0xffff_ffff'u64)
proc shaRotate(value: uint32, amount: int): uint32 = (value shr amount) or (value shl (32 - amount))

proc sha256Digest(input: openArray[uint8], output: var array[32, uint8]) =
  var padded: array[64, uint8]
  for index in 0 ..< input.len: padded[index] = input[index]
  padded[input.len] = 0x80
  let bitLength = uint64(input.len) * 8
  for index in 0 ..< 8: padded[63 - index] = uint8((bitLength shr (8 * index)) and 255)
  var words: array[64, uint32]
  for index in 0 ..< 16:
    let offset = index * 4
    words[index] = (uint32(padded[offset]) shl 24) or (uint32(padded[offset + 1]) shl 16) or
                   (uint32(padded[offset + 2]) shl 8) or uint32(padded[offset + 3])
  for index in 16 ..< 64:
    let x=words[index-15];let y=words[index-2]
    let small0=shaRotate(x,7) xor shaRotate(x,18) xor (x shr 3)
    let small1=shaRotate(y,17) xor shaRotate(y,19) xor (y shr 10)
    words[index]=shaAdd(shaAdd(shaAdd(small1,words[index-7]),small0),words[index-16])
  var state=[0x6a09e667'u32,0xbb67ae85'u32,0x3c6ef372'u32,0xa54ff53a'u32,
             0x510e527f'u32,0x9b05688c'u32,0x1f83d9ab'u32,0x5be0cd19'u32]
  var a=state[0];var b=state[1];var c=state[2];var d=state[3]
  var e=state[4];var f=state[5];var g=state[6];var h=state[7]
  for index in 0 ..< 64:
    let big1=shaRotate(e,6) xor shaRotate(e,11) xor shaRotate(e,25)
    let choose=(e and f) xor ((not e) and g)
    let first=shaAdd(shaAdd(shaAdd(shaAdd(h,big1),choose),ShaK[index]),words[index])
    let big0=shaRotate(a,2) xor shaRotate(a,13) xor shaRotate(a,22)
    let majority=(a and b) xor (a and c) xor (b and c)
    let second=shaAdd(big0,majority)
    h=g;g=f;f=e;e=shaAdd(d,first);d=c;c=b;b=a;a=shaAdd(first,second)
  state[0]=shaAdd(state[0],a);state[1]=shaAdd(state[1],b);state[2]=shaAdd(state[2],c);state[3]=shaAdd(state[3],d)
  state[4]=shaAdd(state[4],e);state[5]=shaAdd(state[5],f);state[6]=shaAdd(state[6],g);state[7]=shaAdd(state[7],h)
  for word in 0 ..< 8:
    for byte in 0 ..< 4: output[word * 4 + byte] = uint8((state[word] shr (24 - 8 * byte)) and 255)

proc base58check_encode*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "base58check_encode".} =
  if values.isNil or length < 2 or length > MaxWords: return -1
  let version = values[0]
  let payloadValue = values[1]
  if version < 0 or version > 255 or payloadValue < 0 or payloadValue > MaxPayload:
    return -1
  let payloadLength = int(payloadValue)
  if int(length) != payloadLength + 2: return -1

  var message: array[MaxPayload + 1, uint8]
  var raw: array[MaxPayload + 5, uint8]
  message[0] = uint8(version)
  raw[0] = uint8(version)
  for index in 0 ..< payloadLength:
    let byte = values[index + 2]
    if byte < 0 or byte > 255: return -1
    message[index + 1] = uint8(byte)
    raw[index + 1] = uint8(byte)
  let messageLength = payloadLength + 1
  var firstDigest: array[32, uint8]
  sha256Digest(message.toOpenArray(0, messageLength - 1), firstDigest)
  var secondDigest: array[32, uint8]
  sha256Digest(firstDigest, secondDigest)

  let rawLength = messageLength + 4
  for index in 0 ..< 4: raw[messageLength + index] = secondDigest[index]
  var leadingZeroes = 0
  while leadingZeroes < rawLength and raw[leadingZeroes] == 0: inc leadingZeroes
  var digits: array[MaxBase58, uint8]
  var digitCount = 0
  for index in leadingZeroes ..< rawLength:
    var carry = uint32(raw[index])
    for digit in 0 ..< digitCount:
      carry += uint32(digits[digit]) * 256
      digits[digit] = uint8(carry mod 58)
      carry = carry div 58
    while carry > 0:
      digits[digitCount] = uint8(carry mod 58)
      inc digitCount
      carry = carry div 58
  let encodedLength = leadingZeroes + digitCount
  if output.isNil or outputCapacity < csize_t(encodedLength): return -2
  var written = 0
  while written < leadingZeroes:
    output[written] = uint8(ord('1'))
    inc written
  while digitCount > 0:
    dec digitCount
    output[written] = uint8(ord(Alphabet[int(digits[digitCount])]))
    inc written
  int64(encodedLength)
