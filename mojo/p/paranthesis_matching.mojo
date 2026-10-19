from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("paranthesis_matching")
fn paranthesis_matching(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>100 or v[0]<1 or v[0]>99 or Int(n)!=Int(v[0])+1:return -1
    var stack=InlineArray[Int64,99](fill=0);var sp=0
    for i in range(1,Int(n)):
        let x=v[i];if x<33 or x>126:return -1
        if x==40 or x==123 or x==91 or x==60:stack[sp]=x;sp+=1
        elif x==41 or x==125 or x==93 or x==62:
            let want=if x==41:40 elif x==125:123 elif x==93:91 else:60
            if sp==0:return 0
            sp-=1;if stack[sp]!=want:return 0
        else:return 0
    return 1 if sp==0 else 0
