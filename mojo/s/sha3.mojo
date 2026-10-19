from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sh3_rot(x:UInt64,n:Int)->UInt64:
    if n==0:return x
    return (x<<UInt(n))|(x>>UInt(64-n))
fn sh3_keccak(s:UnsafePointer[UInt64,MutAnyOrigin]):
    let rc=InlineArray[UInt64,24](1,0x8082,0x800000000000808a,0x8000000080008000,0x808b,0x80000001,0x8000000080008081,0x8000000000008009,0x8a,0x88,0x80008009,0x8000000a,0x8000808b,0x800000000000008b,0x8000000000008089,0x8000000000008003,0x8000000000008002,0x8000000000000080,0x800a,0x800000008000000a,0x8000000080008081,0x8000000000008080,0x80000001,0x8000000080008008)
    let ro=InlineArray[Int32,25](0,1,62,28,27,36,44,6,55,20,3,10,43,25,39,41,45,15,21,8,18,2,61,56,14)
    for round in range(24):
        var c=InlineArray[UInt64,5]();var d=InlineArray[UInt64,5]();var b=InlineArray[UInt64,25]()
        for x in range(5):c[x]=s[x]^s[x+5]^s[x+10]^s[x+15]^s[x+20]
        for x in range(5):d[x]=c[(x+4)%5]^sh3_rot(c[(x+1)%5],1)
        for y in range(5):for x in range(5):s[x+5*y]^=d[x]
        for y in range(5):for x in range(5):let src=x+5*y;let dst=y+5*((2*x+3*y)%5);b[dst]=sh3_rot(s[src],Int(ro[src]))
        for y in range(5):for x in range(5):s[x+5*y]=b[x+5*y]^((~b[(x+1)%5+5*y])&b[(x+2)%5+5*y])
        s[0]^=rc[round]
@export("sha3")
fn sha3(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4098:return -1
    let variant=a[0];let m=a[1];if variant<0 or variant>3 or m<0 or m>4096 or n!=c_size_t(m+2):return -1
    for i in range(Int(m)):if a[i+2]<0 or a[i+2]>255:return -1
    let rate=144 if variant==0 else (136 if variant==1 else (104 if variant==2 else 72));let digest=28 if variant==0 else (32 if variant==1 else (48 if variant==2 else 64))
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(digest):return -2
    var state=InlineArray[UInt64,25]()
    var off=0
    while Int(m)-off>=rate:
        for i in range(rate):state[i/8]^=UInt64(a[off+i+2])<<UInt(8*(i%8))
        sh3_keccak(state.unsafe_ptr());off+=rate
    let rem=Int(m)-off
    for i in range(rem):state[i/8]^=UInt64(a[off+i+2])<<UInt(8*(i%8))
    state[rem/8]^=UInt64(6)<<UInt(8*(rem%8));let last=rate-1;state[last/8]^=UInt64(128)<<UInt(8*(last%8));sh3_keccak(state.unsafe_ptr())
    for i in range(digest):o[i]=UInt8((state[i/8]>>UInt(8*(i%8)))&255)
    return Int64(digest)
