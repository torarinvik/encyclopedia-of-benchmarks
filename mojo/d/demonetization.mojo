from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn demonet_ways(amount:Int64,input:UnsafePointer[Int64,ImmutAnyOrigin],count:Int)->Int64:
    if amount<0:return 0
    if amount==0:return 1
    if count==0:return 0
    let coin=input[count+1]
    return demonet_ways(amount,input,count-1)+demonet_ways(amount-coin,input,count)
@export("demonetization")
fn demonetization(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>6:return -1
    let amount=input[0];let count=input[1]
    if amount< -30 or amount>30 or count<0 or count>4 or length!=c_size_t(count+2):return -1
    for i in range(Int(count)):
        if input[i+2]<1 or input[i+2]>30:return -1
    return demonet_ways(amount,input,Int(count))
