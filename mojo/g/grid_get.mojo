from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("grid_get")
fn grid_get(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4:return -1
    let op=v[0];let columns=v[1];let index=v[2]
    if (op!=0 and op!=1) or columns<1 or columns>1000 or index<0 or index>10000:return -1
    if op==0:
        var remaining=index
        while remaining+1>columns:remaining-=columns
        return remaining+1
    return index//columns+1
