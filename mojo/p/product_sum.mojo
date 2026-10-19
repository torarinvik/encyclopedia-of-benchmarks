from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ps_parse(v:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,inout cursor:Int,depth:Int,nested:Bool,inout valid:Bool)->Int64:
    if depth>16:valid=False;return 0
    var sum=Int64(0)
    while cursor<count:
        let token=v[cursor];cursor+=1
        if token==2002:
            if !nested:valid=False
            return sum*Int64(depth)
        if token==2001:sum+=ps_parse(v,count,cursor,depth+1,True,valid)
        elif token>= -1000 and token<=1000:sum+=token
        else:valid=False;return 0
        if !valid:return 0
    if nested:valid=False
    return sum*Int64(depth)
@export("product_sum")
fn product_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or n!=c_size_t(v[0]+1):return -1
    var cursor=0;var valid=True;let result=ps_parse(v+1,Int(v[0]),cursor,1,False,valid)
    return result if valid and cursor==Int(v[0]) else -1
