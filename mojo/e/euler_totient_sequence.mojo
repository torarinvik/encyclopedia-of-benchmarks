from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

fn euler_seq_append(out:List[UInt8],value:Int):
    if value>=10:euler_seq_append(out,value//10)
    out.append(UInt8(48+value%10))
@export("euler_totient_sequence")
fn euler_totient_sequence(n:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if n<1 or n>80:return -1
    var staged=List[UInt8](capacity=400)
    for value in range(1,Int(n)+1):
        var rem=value;var phi=value;var p=2
        while p*p<=rem:
            if rem%p==0:
                while rem%p==0:rem//=p
                phi-=phi//p
            p+=1
        if rem>1:phi-=phi//rem
        if value>1:staged.append(UInt8(44))
        euler_seq_append(staged,phi)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(staged)):return -2
    for i in range(len(staged)):out[i]=staged[i]
    return Int64(len(staged))
