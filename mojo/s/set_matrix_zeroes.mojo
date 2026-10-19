from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("set_matrix_zeroes")
fn set_matrix_zeroes(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>66:return -1
    let rows=a[0];let cols=a[1];if rows<1 or rows>8 or cols<1 or cols>8 or n!=c_size_t(2+rows*cols):return -1
    var m=InlineArray[Int64,64]();var rz=InlineArray[Bool,8]();var cz=InlineArray[Bool,8]()
    for r in range(Int(rows)):for c in range(Int(cols)):
        let v=a[2+r*Int(cols)+c];if v< -1000000 or v>1000000:return -1
        m[r*Int(cols)+c]=v;if v==0:rz[r]=True;cz[c]=True
    let bytes=Int(rows*cols)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for r in range(Int(rows)):for c in range(Int(cols)):if rz[r] or cz[c]:m[r*Int(cols)+c]=0
    for i in range(Int(rows*cols)):
        let z=bitcast[UInt64](m[i]);for b in range(8):o[i*8+b]=UInt8((z>>UInt(8*b))&255)
    return Int64(bytes)
