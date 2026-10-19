from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn spiral_byte(h:UInt32,b:UInt8)->UInt32:return (h^UInt32(b))*UInt32(16777619)
fn spiral_value(h0:UInt32,x:Int64)->UInt32:
    let bits=UInt32(Int32(x));var h=h0
    for b in range(4):h=spiral_byte(h,UInt8((bits>>(8*b))&255))
    return h
@export("print_amatrix_in_spiral_order")
fn print_amatrix_in_spiral_order(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>66 or v[0]<1 or v[0]>8 or v[1]<1 or v[1]>8 or n!=c_size_t(2+v[0]*v[1]):return -1
    let rows=Int(v[0]);let cols=Int(v[1])
    for i in range(2,Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    var top=0;var bottom=rows-1;var left=0;var right=cols-1;var h=UInt32(2166136261)
    while top<=bottom and left<=right:
        for c in range(left,right+1):h=spiral_value(h,v[2+top*cols+c])
        top+=1
        for r in range(top,bottom+1):h=spiral_value(h,v[2+r*cols+right])
        right-=1
        if top<=bottom:
            for c in range(right,left-1,-1):h=spiral_value(h,v[2+bottom*cols+c])
            bottom-=1
        if left<=right:
            for r in range(bottom,top-1,-1):h=spiral_value(h,v[2+r*cols+left])
            left+=1
    return Int64(h)
