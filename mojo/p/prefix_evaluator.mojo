from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("prefix_evaluator")
fn prefix_evaluator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>129 or v[0]<1 or v[0]>128 or n!=c_size_t(v[0]+1):return -1
    var stack=InlineArray[Int64,128](fill=0);var top=0
    for z in range(Int(v[0])):
        let t=v[Int(v[0])-z]
        if t== -9000000000000000001 or t== -9000000000000000002 or t== -9000000000000000003 or t== -9000000000000000004:
            if top<2:return -1
            let a=stack[top-1];let b=stack[top-2];top-=2;var r=Int64(0)
            if t== -9000000000000000001:r=a+b
            elif t== -9000000000000000002:r=a-b
            elif t== -9000000000000000003:r=a*b
            else:
                if b==0:return -1
                if a== -2147483648 and b== -1:r= -2147483648
                else:
                    let aa=if a<0:-a else:a;let bb=if b<0:-b else:b;r=aa/bb
                    if (a<0)!=(b<0):r=-r
            r=((r+2147483648)%4294967296+4294967296)%4294967296-2147483648
            stack[top]=r;top+=1
        else:
            if t< -2147483648 or t>2147483647 or top>=128:return -1
            stack[top]=t;top+=1
    return stack[0] if top==1 else -1
