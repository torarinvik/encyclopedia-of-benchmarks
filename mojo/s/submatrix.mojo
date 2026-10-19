from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn fnv_feed(h0:UInt64,x:Int64)->UInt64:
    var h=h0;let u=bitcast[UInt64](x)
    for b in range(8):h=(h^((u>>UInt(8*b))&255))*0x100000001b3
    return h
@export("submatrix")
fn submatrix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>70:return -1
    let rows=v[0];let cols=v[1];let rs=v[2];let cs=v[3];let nr=v[4];let nc=v[5]
    if rows<1 or rows>8 or cols<1 or cols>8 or rows*cols>64 or n!=c_size_t(6+rows*cols):return -1
    if rs<0 or rs>rows or cs<0 or cs>cols or nr<0 or nr>rows or nc<0 or nc>cols or rs+nr>rows or cs+nc>cols:return -1
    for i in range(6,Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    var h=fnv_feed(0xcbf29ce484222325,nr);h=fnv_feed(h,nc)
    for r in range(Int(nr)):
        for c in range(Int(nc)):h=fnv_feed(h,v[6+((Int(rs)+r)*Int(cols)+Int(cs)+c)])
    return bitcast[Int64](h)
