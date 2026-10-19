from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("valid_parentheses")
fn valid_parentheses(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        let x=v[i]
        if x!=40 and x!=41 and x!=91 and x!=93 and x!=123 and x!=125:return -1
    var stack=InlineArray[Int64,256](fill=0);var top=0
    for i in range(Int(n)):
        let x=v[i]
        if x==40 or x==91 or x==123:stack[top]=x;top+=1
        else:
            if top==0:return 0
            top-=1
            let expected=40 if x==41 else (91 if x==93 else 123)
            if stack[top]!=expected:return 0
    return 1 if top==0 else 0
