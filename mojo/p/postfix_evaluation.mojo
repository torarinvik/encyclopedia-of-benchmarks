from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("postfix_evaluation")
fn postfix_evaluation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    let invalid=Int64(-1000000001)
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512 or n%2!=0:return invalid
    let count=Int(n)//2;var stack=InlineArray[Int64,256](fill=0);var top=0
    for i in range(count):
        let op=v[2*i];let val=v[2*i+1]
        if op==0:
            if val< -1000000 or val>1000000:return invalid
            stack[top]=val;top+=1
        else:
            if op<1 or op>4 or val!=0 or top<2:return invalid
            let right=stack[top-1];let left=stack[top-2];top-=2
            var z=Int64(0)
            if op==1:z=left+right
            elif op==2:z=left-right
            elif op==3:z=left*right
            else:
                if right==0:return invalid
                let al=if left<0:-left else:left;let ar=if right<0:-right else:right
                z=al/ar
                if (left<0)!=(right<0):z=-z
            if z< -1000000000 or z>1000000000:return invalid
            stack[top]=z;top+=1
    return stack[0] if top==1 else invalid
