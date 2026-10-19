from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("string_is_valid_number")
fn string_is_valid_number(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    var state=0
    for i in range(Int(n)):
        let c=v[i]
        if c>=48 and c<=57:
            if state==0 or state==1:state=2
            elif state==3:state=4
            elif state==5 or state==6:state=7
            elif state!=2 and state!=4 and state!=7:return 0
        elif c==43 or c==45:
            if state==0:state=1
            elif state==5:state=6
            else:return 0
        elif c==46:
            if state==0 or state==1:state=3
            elif state==2:state=4
            else:return 0
        elif c==101 or c==69:
            if state==2 or state==4:state=5
            else:return 0
        else:return 0
    return 1 if state==2 or state==4 or state==7 else 0
