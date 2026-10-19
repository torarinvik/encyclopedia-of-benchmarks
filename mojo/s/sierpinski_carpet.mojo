from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn carpet_filled(r0:Int,c0:Int)->Bool:
    var r=r0;var c=c0
    while r!=0 or c!=0:if r%3==1 and c%3==1:return False;r/=3;c/=3
    return True
@export("sierpinski_carpet")
fn sierpinski_carpet(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let d=a[0];let f=a[1];let h=a[2];if d<0 or d>4 or f<32 or f>126 or h<32 or h>126 or f==h:return -1
    var side=1;for _ in range(Int(d)):side*=3
    let bytes=8+side*side+side-1;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    let z=bitcast[UInt64](Int64(side));for b in range(8):o[b]=UInt8((z>>UInt(8*b))&255)
    var p=8
    for r in range(side):
        for c in range(side):o[p]=UInt8(f if carpet_filled(r,c) else h);p+=1
        if r+1<side:o[p]=10;p+=1
    return Int64(bytes)
