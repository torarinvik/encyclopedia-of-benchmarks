from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn dice_required(rem:Int,depth:Int)->Int:
    if rem==0:return depth+1
    var total=0;let maxface=rem if rem<6 else 6
    for face in range(1,maxface+1):total+=dice_required(rem-face,depth+1)
    return total
fn dice_emit(rem:Int,depth:Int,mut digits:List[Int],mut output:List[UInt8]):
    if rem==0:
        for i in range(depth):output.append(UInt8(digits[i]))
        output.append(10);return
    let maxface=rem if rem<6 else 6
    for face in range(1,maxface+1):digits[depth]=48+face;dice_emit(rem-face,depth+1,digits,output)
@export("dice_thrower")
fn dice_thrower(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<0 or input[0]>8:return -1
    let target=Int(input[0]);let required=dice_required(target,0)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    var digits=List[Int](length=8,fill=0);var staged=List[UInt8](capacity=696);dice_emit(target,0,digits,staged)
    for i in range(len(staged)):out[i]=staged[i]
    return Int64(len(staged))
