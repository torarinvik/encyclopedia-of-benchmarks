from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hill_encoder")
fn hill_encoder(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<10:return -1
    let m=a[0];if m<0 or m>64 or n!=c_size_t(10+m):return -1
    for i in range(Int(m)):if a[1+i]<65 or a[1+i]>90:return -1
    for i in range(9):if a[1+Int(m)+i]< -2 or a[1+Int(m)+i]>2:return -1
    let padded=((Int(m)+2)//3)*3;let words=padded;let bytes=words*8
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var text=InlineArray[Int64,66](fill=32)
    for i in range(Int(m)):text[i]=a[i+1]
    for block in range(padded//3):
        for row in range(3):
            var value:Int64=0
            for col in range(3):value+=a[1+Int(m)+row*3+col]*(text[block*3+col]-65)
            text[block*3+row]=value
    for i in range(padded):
        let u=bitcast[UInt64](text[i])
        for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
    return Int64(bytes)
