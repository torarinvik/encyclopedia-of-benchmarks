const MaxKey = 64
const MaxWords = 67

proc rol(value: uint32, amount: int): uint32 =
  (value shl amount) or (value shr (32 - amount))

proc compress(state: var array[5, uint32], block: array[64, uint8]) =
  var schedule: array[80, uint32]
  for i in 0 ..< 16:
    let j = 4 * i
    schedule[i] = (uint32(block[j]) shl 24) or (uint32(block[j+1]) shl 16) or
                  (uint32(block[j+2]) shl 8) or uint32(block[j+3])
  for i in 16 ..< 80:
    schedule[i] = rol(schedule[i-3] xor schedule[i-8] xor schedule[i-14] xor schedule[i-16], 1)
  var a=state[0]; var b=state[1]; var c=state[2]; var d=state[3]; var e=state[4]
  for i in 0 ..< 80:
    var f, k: uint32
    if i < 20: f=(b and c) or ((not b) and d); k=0x5a827999'u32
    elif i < 40: f=b xor c xor d; k=0x6ed9eba1'u32
    elif i < 60: f=(b and c) or (b and d) or (c and d); k=0x8f1bbcdc'u32
    else: f=b xor c xor d; k=0xca62c1d6'u32
    let temp=rol(a,5) +% f +% e +% k +% schedule[i]
    e=d; d=c; c=rol(b,30); b=a; a=temp
  state[0]=state[0]+%a;state[1]=state[1]+%b;state[2]=state[2]+%c;state[3]=state[3]+%d;state[4]=state[4]+%e

proc initial(): array[5, uint32] =
  [0x67452301'u32,0xefcdab89'u32,0x98badcfe'u32,0x10325476'u32,0xc3d2e1f0'u32]

proc serialize(state: array[5,uint32], output: var array[20,uint8]) =
  for i in 0 ..< 5:
    output[4*i]=uint8(state[i] shr 24);output[4*i+1]=uint8((state[i] shr 16) and 255)
    output[4*i+2]=uint8((state[i] shr 8) and 255);output[4*i+3]=uint8(state[i] and 255)

proc compute(input: ptr UncheckedArray[int64], keyLength: int, output: var array[6,uint8]) =
  var key = default(array[64,uint8]);var block = default(array[64,uint8]);var inner: array[20,uint8]
  for i in 0 ..< keyLength: key[i]=uint8(input[i+1])
  for i in 0 ..< 64: block[i]=key[i] xor 0x36'u8
  var state=initial();compress(state,block);block=default(array[64,uint8])
  let counter=uint64(input[keyLength+1]) div 30
  for i in 0 ..< 8: block[i]=uint8((counter shr (56-8*i)) and 255)
  block[8]=0x80;block[62]=2;block[63]=0x40;compress(state,block);serialize(state,inner)
  for i in 0 ..< 64: block[i]=key[i] xor 0x5c'u8
  state=initial();compress(state,block);block=default(array[64,uint8])
  for i in 0 ..< 20: block[i]=inner[i]
  block[20]=0x80;block[62]=2;block[63]=0xa0;compress(state,block);serialize(state,inner)
  let offset=int(inner[19] and 15)
  var binary=(uint32(inner[offset]) shl 24) or (uint32(inner[offset+1]) shl 16) or
             (uint32(inner[offset+2]) shl 8) or uint32(inner[offset+3])
  binary=binary and 0x7fffffff'u32
  var value=binary mod 1_000_000'u32
  for i in countdown(5,0): output[i]=uint8(ord('0')+int(value mod 10));value=value div 10

proc time_based_one_time_password_algorithm*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 3 or length > MaxWords: return -1
  let keyWord=input[0]
  if keyWord < 16 or keyWord > MaxKey or length != csize_t(keyWord+2): return -1
  let keyLength=int(keyWord)
  for i in 0 ..< keyLength:
    if input[i+1] < 0 or input[i+1] > 255: return -1
  if input[keyLength+1] < 0: return -1
  var staged: array[6,uint8];compute(input,keyLength,staged)
  if output.isNil or capacity < 6: return -2
  for i in 0 ..< 6: output[i]=staged[i]
  6
