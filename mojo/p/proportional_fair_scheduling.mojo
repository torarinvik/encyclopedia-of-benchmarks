from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pfs_store(output:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[pos+b]=UInt8((bits>>UInt(8*b))&255)
@export("proportional_fair_scheduling")
fn proportional_fair_scheduling(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>131:return -1
    if values[0]<0 or values[0]>64 or values[1]<1 or values[1]>1000000:return -1
    let count=Int(values[0]);let total=values[1]
    if length!=c_size_t(2+2*count):return -1
    var ids=InlineArray[Int64,64](fill=0);var weights=InlineArray[Int64,64](fill=0);var sum=Int64(0)
    for i in range(count):
        let id=values[2+2*i];let weight=values[3+2*i]
        if id< -2147483648 or id>2147483647 or weight<1 or weight>1000000:return -1
        ids[i]=id;weights[i]=weight;sum+=weight
    if count==0:return 0
    let needed=count*16
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    for i in range(count):
        let quotient=Float64(weights[i])/Float64(sum);let share=quotient*Float64(total);let allocation=Int64(share)
        pfs_store(output,i*16,ids[i]);pfs_store(output,i*16+8,allocation)
    return Int64(needed)
