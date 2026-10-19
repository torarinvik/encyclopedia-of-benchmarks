from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("duplicate_brackets")
fn duplicate_brackets(packed:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if packed==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let count=packed[0]
    if count<0 or count>256 or length!=c_size_t(count+1):return -1
    var depth=0
    for i in range(Int(count)):
        let ch=packed[i+1]
        if ch<32 or ch>126:return -1
        if ch==40:depth+=1
        elif ch==41:depth-=1;if depth<0:return -1
    if depth!=0:return -1
    var stack=List[Int64](capacity=256)
    for i in range(Int(count)):
        let ch=packed[i+1]
        if ch==41:
            if len(stack)==0 or stack[len(stack)-1]==40:return 1
            while len(stack)>0 and stack[len(stack)-1]!=40:stack.pop()
            if len(stack)>0:stack.pop()
        else:stack.append(ch)
    return 0
