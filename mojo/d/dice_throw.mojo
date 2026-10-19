from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("dice_throw")
fn dice_throw(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    let fv=input[0];let dv=input[1];let tv=input[2]
    if fv<1 or fv>8 or dv<1 or dv>8 or tv<0 or tv>64:return -1
    let faces=Int(fv);let dice=Int(dv);let target=Int(tv);var table=List[Int64](length=9*65,fill=0)
    for total in range(1,faces+1):
        if total<=target:table[65+total]=1
    for die in range(2,dice+1):
        for total in range(1,target+1):
            for face in range(1,total):
                if face<=faces:table[die*65+total]+=table[(die-1)*65+total-face]
    return table[dice*65+target]
