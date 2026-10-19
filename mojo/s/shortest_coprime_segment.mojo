from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sc_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("shortest_coprime_segment")
fn shortest_coprime_segment(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>128 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]<1 or a[i]>1000:return -1
    var best=129;var begin=0
    for l in range(Int(n)):
        var g:Int64=0
        for r in range(l,Int(n)):
            g=sc_gcd(g,a[r])
            if g==1:
                if r-l+1<best:best=r-l+1;begin=l
                break
    if best>Int(n):return 0
    let bytes=best*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(best):let z=bitcast[UInt64](a[begin+i]);for b in range(8):o[i*8+b]=UInt8((z>>UInt(8*b))&255)
    return Int64(bytes)
