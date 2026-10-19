from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_valid_parentheses_stack")
fn longest_valid_parentheses_stack(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]!=40 and v[i]!=41:return -1
    var unmatched=InlineArray[Int64,4097](fill=0);var top=0;unmatched[0]= -1;var best=0
    for i in range(Int(n)):
        if v[i]==40:top+=1;unmatched[top]=Int64(i)
        else:
            if top==0:unmatched[0]=Int64(i)
            else:
                top-=1;let current=i-Int(unmatched[top]);best=max(best,current)
    return Int64(best)
