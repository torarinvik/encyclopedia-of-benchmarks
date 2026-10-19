from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn egcd_put_i32(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt32(value)
    for b in range(4):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("extended_euclidean_algorithm")
fn extended_euclidean_algorithm(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2 or input[0]<1 or input[0]>2147483647 or input[1]<1 or input[1]>2147483647:return -1
    var old_r=input[0];var r=input[1];var old_x:Int64=1;var x:Int64=0;var old_y:Int64=0;var y:Int64=1
    while r!=0:
        let q=old_r/r;let nr=old_r-q*r;old_r=r;r=nr
        let nx=old_x-q*x;old_x=x;x=nx
        let ny=old_y-q*y;old_y=y;y=ny
    if old_r>2147483647 or old_x< -2147483648 or old_x>2147483647 or old_y< -2147483648 or old_y>2147483647:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<12:return -2
    egcd_put_i32(out,0,old_r);egcd_put_i32(out,4,old_x);egcd_put_i32(out,8,old_y)
    return 12
