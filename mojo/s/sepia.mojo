from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sepia")
fn sepia(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>196:return -1
    let h=a[0];let w=a[1];let factor=a[2]
    if h<1 or h>8 or w<1 or w>8 or factor<0 or factor>255 or n!=c_size_t(3+3*h*w):return -1
    for i in range(Int(3*h*w)):
        let v=a[i+3];if v!=0 and v!=64 and v!=128 and v!=255:return -1
    let bytes=Int(3*h*w);if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var out=InlineArray[UInt8,192]()
    for p in range(Int(h*w)):
        let b=Float64(a[3+3*p]);let g=Float64(a[4+3*p]);let r=Float64(a[5+3*p])
        let gray=Int64(0.2126*r+0.587*g+0.114*b)
        out[3*p]=UInt8(gray);out[3*p+1]=UInt8(min(255,gray+factor));out[3*p+2]=UInt8(min(255,gray+2*factor))
    for i in range(bytes):o[i]=out[i]
    return Int64(bytes)
