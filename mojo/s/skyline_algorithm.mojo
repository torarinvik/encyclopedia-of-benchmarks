from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn skyline_mark(a:UnsafePointer[Int64,ImmutAnyOrigin],keep:UnsafePointer[Bool,MutAnyOrigin],lo:Int,hi:Int):
    if hi-lo==1:keep[lo]=True;return
    let mid=(lo+hi)/2
    skyline_mark(a,keep,lo,mid);skyline_mark(a,keep,mid,hi)
    var miny:Int64=2147483648
    for i in range(lo,mid):if keep[i] and a[2+2*i]<miny:miny=a[2+2*i]
    for i in range(mid,hi):if keep[i] and a[2+2*i]>=miny:keep[i]=False
@export("skyline_algorithm")
fn skyline_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>130:return -1
    let count=a[0];if count<1 or count>64 or n!=c_size_t(1+2*count):return -1
    for i in range(Int(count)):
        let x=a[1+2*i];let y=a[2+2*i]
        if x< -2147483648 or x>2147483647 or y<1 or y>2147483647 or (i>0 and x<=a[2*i-1]):return -1
    var keep=InlineArray[Bool,64]()
    skyline_mark(a,keep.unsafe_ptr(),0,Int(count))
    var outn=0;for i in range(Int(count)):if keep[i]:outn+=1
    let bytes=1+outn*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    o[0]=UInt8(outn);var p=1
    for i in range(Int(count)):
        if keep[i]:
            for v in range(2):let bits=UInt32(Int32(a[1+2*i+v]));for b in range(4):o[p]=UInt8((bits>>(b*8))&255);p+=1
    return bytes
