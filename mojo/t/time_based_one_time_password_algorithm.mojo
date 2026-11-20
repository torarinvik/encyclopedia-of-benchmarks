from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_KEY: Int = 64
const MAX_WORDS: Int = 67

def add32(a: UInt32, b: UInt32) -> UInt32:
    return ((a.to_u64() + b.to_u64()) & 0xffffffff).to_u32()

def rol(x: UInt32, n: Int) -> UInt32:
    return (x << n) | (x >> (32 - n))

def compress(inout state: InlineArray[UInt32,5], block: InlineArray[UInt8,64]):
    var w = InlineArray[UInt32,80]()
    for i in range(16):
        let j = 4 * i
        w[i] = (block[j].to_u32() << 24) | (block[j+1].to_u32() << 16) | (block[j+2].to_u32() << 8) | block[j+3].to_u32()
    for i in range(16,80):
        w[i] = rol(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16],1)
    var a=state[0];var b=state[1];var c=state[2];var d=state[3];var e=state[4]
    for i in range(80):
        var f: UInt32 = 0
        var k: UInt32 = 0
        if i < 20:
            f=(b&c)|((~b)&d);k=0x5a827999
        elif i < 40:
            f=b^c^d;k=0x6ed9eba1
        elif i < 60:
            f=(b&c)|(b&d)|(c&d);k=0x8f1bbcdc
        else:
            f=b^c^d;k=0xca62c1d6
        let t=add32(add32(add32(add32(rol(a,5),f),e),k),w[i])
        e=d;d=c;c=rol(b,30);b=a;a=t
    state[0]=add32(state[0],a);state[1]=add32(state[1],b);state[2]=add32(state[2],c);state[3]=add32(state[3],d);state[4]=add32(state[4],e)

def initial() -> InlineArray[UInt32,5]:
    return InlineArray[UInt32,5](0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0)

def serialize(state: InlineArray[UInt32,5], inout output: InlineArray[UInt8,20]):
    for i in range(5):
        output[4*i]=(state[i] >> 24).to_u8()
        output[4*i+1]=(state[i] >> 16).to_u8()
        output[4*i+2]=(state[i] >> 8).to_u8()
        output[4*i+3]=state[i].to_u8()

fn calculate(input: UnsafePointer[Int64,ImmutAnyOrigin], key_length: Int) -> InlineArray[UInt8,6]:
    var key = InlineArray[UInt8,64]()
    var block = InlineArray[UInt8,64]()
    var inner = InlineArray[UInt8,20]()
    for i in range(key_length): key[i]=input[i+1].to_u8()
    for i in range(64): block[i]=key[i]^0x36
    var state=initial();compress(state,block)
    for i in range(64): block[i]=0
    let counter=input[key_length+1].to_u64()/30
    for i in range(8): block[i]=((counter >> (56-8*i)) & 255).to_u8()
    block[8]=0x80;block[62]=2;block[63]=0x40;compress(state,block);serialize(state,inner)
    for i in range(64): block[i]=key[i]^0x5c
    state=initial();compress(state,block)
    for i in range(64): block[i]=0
    for i in range(20): block[i]=inner[i]
    block[20]=0x80;block[62]=2;block[63]=0xa0;compress(state,block);serialize(state,inner)
    let offset=(inner[19]&15).to_int()
    var binary=(inner[offset].to_u32()<<24)|(inner[offset+1].to_u32()<<16)|(inner[offset+2].to_u32()<<8)|inner[offset+3].to_u32()
    binary=binary&0x7fffffff
    var value=binary%1000000
    var output=InlineArray[UInt8,6]()
    for i in range(6):
        let place=5-i
        output[place]=(48+(value%10)).to_u8()
        value=value/10
    return output

@export("time_based_one_time_password_algorithm")
fn time_based_one_time_password_algorithm(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
  output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length < 3 or length > MAX_WORDS: return -1
    let key_word=input[0]
    if key_word < 16 or key_word > MAX_KEY or length != key_word.to_int()+2: return -1
    let key_length=key_word.to_int()
    for i in range(key_length):
        if input[i+1] < 0 or input[i+1] > 255: return -1
    if input[key_length+1] < 0: return -1
    let staged=calculate(input,key_length)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity < 6: return -2
    for i in range(6): output[i]=staged[i]
    return 6
