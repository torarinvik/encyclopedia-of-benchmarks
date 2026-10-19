from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("hamming_code")
fn hamming_code(input:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let r=input[0];let m=input[1]
    if r<1 or r>5 or m<1 or m>32 or n!=c_size_t(2+m) or r+m<=((Int64(1)<<Int(r))-(m-1)):return -1
    for i in range(Int(m)):if input[2+i]!=48 and input[2+i]!=49:return -1
    let total=Int(r+m);let highest=1<<(Int(r)-1)
    if total<highest:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(total+1):return -2
    var code=List[UInt8](length=total,fill=48);var data=0
    for pos in range(1,total+1):
        let is_power=(pos&(pos-1))==0
        if not is_power or pos>highest:code[pos-1]=UInt8(input[2+data]);data+=1
    for bit in range(Int(r)):
        let parity=1<<bit;var value=0
        for pos in range(1,total+1):if (pos&parity)!=0 and code[pos-1]==49:value^=1
        code[parity-1]=UInt8(48+value)
    for i in range(total):out[i]=code[i]
    out[total]=0
    return Int64(total)
