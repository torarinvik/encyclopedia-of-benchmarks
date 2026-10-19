from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("erosion_operation")
fn erosion_operation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>38:return -1
    let h=input[0];let w=input[1]
    if h<1 or h>6 or w<1 or w>6 or length!=c_size_t(2+h*w):return -1
    for i in range(Int(h*w)):
        if input[2+i]!=0 and input[2+i]!=1:return -1
    var result:UInt64=0
    for y in range(Int(h)):
        for x in range(Int(w)):
            if input[2+y*Int(w)+x]==1 and y>0 and y+1<Int(h) and x>0 and x+1<Int(w) and input[2+(y-1)*Int(w)+x]==1 and input[2+(y+1)*Int(w)+x]==1 and input[2+y*Int(w)+x-1]==1 and input[2+y*Int(w)+x+1]==1:
                result|=UInt64(1)<<UInt(y*Int(w)+x)
    return bitcast[Int64](result)
