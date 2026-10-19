from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("power_for_huge_numbers")
fn power_for_huge_numbers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<1 or v[0]>10000 or v[1]<0 or v[1]>128:return -1
    var digits=InlineArray[UInt8,513](fill=0);digits[0]=1;var count=1
    for _ in range(Int(v[1])):
        var carry=UInt32(0)
        for i in range(count):
            let prod=UInt32(digits[i])*UInt32(v[0])+carry
            digits[i]=UInt8(prod%10);carry=prod//10
        while carry!=0:
            digits[count]=UInt8(carry%10);count+=1;carry//=10
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):out[i]=UInt8(48+digits[count-1-i])
    return Int64(count)
