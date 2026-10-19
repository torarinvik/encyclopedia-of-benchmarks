from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("shortest_palindrome")
fn shortest_palindrome(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]<32 or a[i]>126:return -1
    if n==0:return 0
    var pi=InlineArray[Int32,64]()
    for i in range(1,Int(n)):
        var j=Int(pi[i-1]);while j>0 and a[j]!=a[i]:j=Int(pi[j-1])
        if a[j]==a[i]:j+=1
        pi[i]=Int32(j)
    var matched=0
    for i in range(Int(n)):
        let v=a[Int(n)-1-i]
        while matched>0 and v!=a[matched]:matched=Int(pi[matched-1])
        if v==a[matched]:matched+=1
    let bytes=2*Int(n)-matched;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(n)):o[i]=UInt8(a[Int(n)-1-i])
    for i in range(matched,Int(n)):o[Int(n)+i-matched]=UInt8(a[i])
    return Int64(bytes)
