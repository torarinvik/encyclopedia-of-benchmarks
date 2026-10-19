from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("minimum_operations_to_move_all_balls")
fn minimum_operations_to_move_all_balls(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>256 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var right_ones:Int64=0;var right_dist:Int64=0
    for i in range(Int(n)):
        if v[i]!=0 and v[i]!=1:return -1
        if v[i]==1:right_ones+=1;right_dist+=Int64(i)
    if cap<c_size_t(Int(n)*2) or (n>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var left_ones:Int64=0;var left_dist:Int64=0
    for i in range(Int(n)):
        if v[i]==1:right_ones-=1;left_ones+=1
        let distance=left_dist+right_dist;let u=UInt16(distance)
        out[2*i]=UInt8(u&255);out[2*i+1]=UInt8(u>>8)
        right_dist-=right_ones;left_dist+=left_ones
    return Int64(n)
