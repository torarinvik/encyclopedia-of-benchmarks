from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime RC:InlineArray[UInt64,24]=InlineArray[UInt64,24](0x1,0x8082,0x800000000000808a,0x8000000080008000,0x808b,0x80000001,0x8000000080008081,0x8000000000008009,0x8a,0x88,0x80008009,0x8000000a,0x8000808b,0x800000000000008b,0x8000000000008089,0x8000000000008003,0x8000000000008002,0x8000000000000080,0x800a,0x800000008000000a,0x8000000080008081,0x8000000000008080,0x80000001,0x8000000080008008)
comptime ROT:InlineArray[Int,25]=InlineArray[Int,25](0,1,62,28,27,36,44,6,55,20,3,10,43,25,39,41,45,15,21,8,18,2,61,56,14)
fn rol(x:UInt64,r:Int)->UInt64:
    if r==0:return x
    return (x<<UInt(r))|(x>>UInt(64-r))
fn keccak(s:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,n:Int)->InlineArray[UInt64,4]:
    var block=InlineArray[UInt8,136](fill=0)
    for i in range(n):block[i]=UInt8(s[start+i])
    block[n]=block[n]^1;block[135]=block[135]^128
    var state=InlineArray[UInt64,25](fill=0)
    for lane in range(17):
        for b in range(8):state[lane]=state[lane]|(UInt64(block[lane*8+b])<<UInt(8*b))
    for round in range(24):
        var col=InlineArray[UInt64,5](fill=0);var delta=InlineArray[UInt64,5](fill=0)
        for x in range(5):col[x]=state[x]^state[x+5]^state[x+10]^state[x+15]^state[x+20]
        for x in range(5):delta[x]=col[(x+4)%5]^rol(col[(x+1)%5],1)
        var moved=InlineArray[UInt64,25](fill=0)
        for y in range(5):
            for x in range(5):
                let src=x+5*y;let dst=y+5*((2*x+3*y)%5);moved[dst]=rol(state[src]^delta[x],ROT[src])
        for y in range(5):
            for x in range(5):state[x+5*y]=moved[x+5*y]^((~moved[(x+1)%5+5*y])&moved[(x+2)%5+5*y])
        state[0]=state[0]^RC[round]
    var result=InlineArray[UInt64,4](fill=0)
    for i in range(4):result[i]=state[i]
    return result
@export("string_hash_equality")
fn string_hash_equality(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>131:return -1
    if v[0]<0 or v[0]>64 or v[1]<0 or v[1]>64 or n!=c_size_t(2+v[0]+v[1]):return -1
    for i in range(2,Int(n)):if v[i]<0 or v[i]>255:return -1
    let a=keccak(v,2,Int(v[0]));let b=keccak(v,2+Int(v[0]),Int(v[1]))
    for i in range(4):if a[i]!=b[i]:return 0
    return 1
