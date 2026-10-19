from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pascal_triangle_benchmark")
fn pascal_triangle(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>30:return -1
    let rows=Int(v[0]);var a=InlineArray[Int64,30](fill=0);a[0]=1;var h:Int64=0
    for r in range(rows):for c in range(r,0,-1):a[c]+=a[c-1];for c in range(r+1):h=(h*31+a[c]%1000000007)%1000000007
    return h
