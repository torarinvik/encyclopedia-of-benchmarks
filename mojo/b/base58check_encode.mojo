from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_WORDS = 35
const MAX_PAYLOAD = 32
const MAX_BASE58 = 51
const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

fn bc_add32(a: UInt32, b: UInt32) -> UInt32:
    return UInt32((UInt64(a) + UInt64(b)) & 0xffffffff)

fn bc_rotr(x: UInt32, n: Int) -> UInt32:
    return (x >> UInt(n)) | (x << UInt(32 - n))

fn bc_sha256(input: InlineArray[UInt8, 33], length: Int,
             output: UnsafePointer[UInt8, MutAnyOrigin]):
    let k = InlineArray[UInt32, 64](
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2)
    var padded = InlineArray[UInt8, 64]()
    for i in range(length): padded[i] = input[i]
    padded[length] = 128
    let bit_length = UInt64(length) * 8
    for i in range(8): padded[63 - i] = UInt8((bit_length >> UInt(8 * i)) & 255)
    var h = InlineArray[UInt32, 8](
        0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
        0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19)
    var w = InlineArray[UInt32, 64]()
    for i in range(16):
        let p = i * 4
        w[i] = (UInt32(padded[p]) << 24) | (UInt32(padded[p+1]) << 16) | (UInt32(padded[p+2]) << 8) | UInt32(padded[p+3])
    for i in range(16, 64):
        let x = w[i-15]
        let y = w[i-2]
        let s0 = bc_rotr(x,7) ^ bc_rotr(x,18) ^ (x >> 3)
        let s1 = bc_rotr(y,17) ^ bc_rotr(y,19) ^ (y >> 10)
        w[i] = bc_add32(bc_add32(bc_add32(w[i-16],s0),w[i-7]),s1)
    var a=h[0];var b=h[1];var c=h[2];var d=h[3]
    var e=h[4];var f=h[5];var g=h[6];var hh=h[7]
    for i in range(64):
        let s1=bc_rotr(e,6)^bc_rotr(e,11)^bc_rotr(e,25)
        let choose=(e&f)^((~e)&g)
        let t1=bc_add32(bc_add32(bc_add32(bc_add32(hh,s1),choose),k[i]),w[i])
        let s0=bc_rotr(a,2)^bc_rotr(a,13)^bc_rotr(a,22)
        let majority=(a&b)^(a&c)^(b&c)
        let t2=bc_add32(s0,majority)
        hh=g;g=f;f=e;e=bc_add32(d,t1);d=c;c=b;b=a;a=bc_add32(t1,t2)
    h[0]=bc_add32(h[0],a);h[1]=bc_add32(h[1],b);h[2]=bc_add32(h[2],c);h[3]=bc_add32(h[3],d)
    h[4]=bc_add32(h[4],e);h[5]=bc_add32(h[5],f);h[6]=bc_add32(h[6],g);h[7]=bc_add32(h[7],hh)
    for i in range(8):
        for byte in range(4): output[i*4+byte]=UInt8((h[i]>>UInt(24-8*byte))&255)

@export("base58check_encode")
fn base58check_encode(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_WORDS: return -1
    let version=values[0]
    let payload_value=values[1]
    if version<0 or version>255 or payload_value<0 or payload_value>32: return -1
    let payload_length=Int(payload_value)
    if length != c_size_t(payload_length+2): return -1
    var message=InlineArray[UInt8,33]()
    var raw=InlineArray[UInt8,37]()
    message[0]=UInt8(version);raw[0]=UInt8(version)
    for i in range(payload_length):
        let byte=values[i+2]
        if byte<0 or byte>255:return -1
        message[i+1]=UInt8(byte);raw[i+1]=UInt8(byte)
    let message_length=payload_length+1
    var first=InlineArray[UInt8,32]()
    bc_sha256(message,message_length,first.unsafe_ptr())
    var second_input=InlineArray[UInt8,33]()
    for i in range(32):second_input[i]=first[i]
    var second=InlineArray[UInt8,32]()
    bc_sha256(second_input,32,second.unsafe_ptr())
    let raw_length=message_length+4
    for i in range(4):raw[message_length+i]=second[i]
    var leading_zeroes=0
    while leading_zeroes<raw_length and raw[leading_zeroes]==0:leading_zeroes+=1
    var digits=InlineArray[UInt8,MAX_BASE58]()
    var digit_count=0
    for i in range(leading_zeroes,raw_length):
        var carry=UInt32(raw[i])
        for j in range(digit_count):
            carry+=UInt32(digits[j])*256
            digits[j]=UInt8(carry%58)
            carry/=58
        while carry>0:
            digits[digit_count]=UInt8(carry%58);digit_count+=1;carry/=58
    let encoded_length=leading_zeroes+digit_count
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or output_capacity<c_size_t(encoded_length):return -2
    var written=0
    while written<leading_zeroes:output[written]=UInt8(49);written+=1
    while digit_count>0:
        digit_count-=1
        output[written]=UInt8(ALPHABET[digits[digit_count]])
        written+=1
    return Int64(encoded_length)
