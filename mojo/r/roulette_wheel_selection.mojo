from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("roulette_wheel_selection")
fn roulette_wheel_selection(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>131 or v[0]<1 or v[0]>128 or Int(n)!=Int(v[0])+2:return -1
    let count=Int(v[0]);var total:Int64=0
    for i in range(count):let x=v[1+i];if x<1 or x>1000000 or total>128000000-x:return -1;total+=x
    let ticket=v[1+count];if ticket<0 or ticket>=total:return -1
    var sum:Int64=0
    for i in range(count):sum+=v[1+i];if ticket<sum:return Int64(i+1)
    return -1
