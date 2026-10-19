from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_of_ways_to_select_buildings")
fn number_of_ways_to_select_buildings(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096:return -1
    var left0:Int64=0;var left1:Int64=0;var pairs01:Int64=0;var pairs10:Int64=0;var total:Int64=0
    for i in range(Int(n)):
        if a==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
        let x=a[i]
        if x==48:total+=pairs10;pairs10+=left1;left0+=1
        elif x==49:total+=pairs01;pairs01+=left0;left1+=1
        else:return -1
    return total
