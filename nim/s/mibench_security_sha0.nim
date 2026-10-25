const InvalidResult: int64 = -1
const OutputError: int64 = -2
const MaxMessageBytes = 55

proc rol32(value: uint32, shift: int): uint32 = (value shl shift) or (value shr (32 - shift))
proc add32(left, right: uint32): uint32 = uint32((uint64(left) + uint64(right)) and 0xFFFF_FFFF'u64)

proc transformSha0(block: array[64, uint8], state: var array[5, uint32]) =
  var words: array[80, uint32]
  for i in 0 ..< 16:
    let p = i * 4
    words[i] = (uint32(block[p]) shl 24) or (uint32(block[p+1]) shl 16) or
      (uint32(block[p+2]) shl 8) or uint32(block[p+3])
  for i in 16 ..< 80:
    words[i] = words[i-3] xor words[i-8] xor words[i-14] xor words[i-16]
  var a=state[0]; var b=state[1]; var c=state[2]; var d=state[3]; var e=state[4]
  for i in 0 ..< 80:
    var f, k: uint32
    if i < 20: f=(b and c) or ((not b) and d); k=0x5A827999'u32
    elif i < 40: f=b xor c xor d; k=0x6ED9EBA1'u32
    elif i < 60: f=(b and c) or (b and d) or (c and d); k=0x8F1BBCDC'u32
    else: f=b xor c xor d; k=0xCA62C1D6'u32
    let temp=add32(add32(add32(add32(rol32(a,5),f),e),words[i]),k)
    e=d; d=c; c=rol32(b,30); b=a; a=temp
  state[0]=add32(state[0],a); state[1]=add32(state[1],b); state[2]=add32(state[2],c)
  state[3]=add32(state[3],d); state[4]=add32(state[4],e)

proc mibench_security_sha0*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mibench_security_sha0".} =
  if input.isNil or inputLength < 1 or inputLength > MaxMessageBytes + 2: return InvalidResult
  let messageLength = input[0]
  if messageLength < 0 or messageLength > MaxMessageBytes or inputLength != csize_t(messageLength) + 1:
    return InvalidResult
  for i in 1 ..< int(inputLength):
    if input[i] < 0 or input[i] > 255: return InvalidResult
  var block: array[64, uint8]
  for i in 0 ..< int(messageLength): block[i] = uint8(input[i+1])
  block[int(messageLength)] = 0x80
  let bitLength = uint64(messageLength) * 8
  for i in 0 ..< 8: block[63-i] = uint8((bitLength shr (8*i)) and 255)
  var state = [0x67452301'u32, 0xEFCDAB89'u32, 0x98BADCFE'u32, 0x10325476'u32, 0xC3D2E1F0'u32]
  transformSha0(block, state)
  if output.isNil or outputCapacity < 20: return OutputError
  for i in 0 ..< 5:
    for byte in 0 ..< 4: output[i*4+byte] = uint8((state[i] shr (24-8*byte)) and 255)
  20
