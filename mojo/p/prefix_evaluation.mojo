from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("prefix_evaluation")
fn prefix_evaluation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>63 or v[0]<1 or v[0]>62 or n!=c_size_t(v[0]+1):return -1.0e300
    var tok=InlineArray[Int64,31](fill=0);var count=0;var need=True
    for i in range(1,Int(n)):
        let c=v[i]
        if c<0 or c>127:return -1.0e300
        if c==32:
            if need:return -1.0e300
            need=True;continue
        if not ((c==43 or c==45 or c==42 or c==47) or (c>=48 and c<=57)) or not need or count>=31:return -1.0e300
        tok[count]=c;count+=1;need=False
    if need or count==0:return -1.0e300
    var stack=InlineArray[Float64,31](fill=0.0);var top=0
    for z in range(count):
        let c=tok[count-1-z]
        if c>=48 and c<=57:stack[top]=Float64(c-48);top+=1;continue
        if top<2:return -1.0e300
        let first=stack[top-1];let second=stack[top-2];top-=2
        if c==43:stack[top]=first+second
        elif c==45:stack[top]=first-second
        elif c==42:stack[top]=first*second
        else:
            if second==0:return -1.0e300
            stack[top]=first/second
        top+=1
    return stack[0] if top==1 else -1.0e300
