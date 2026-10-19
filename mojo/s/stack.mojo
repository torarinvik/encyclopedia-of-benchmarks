from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("stack_benchmark")
fn stack_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or n%2!=0 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let ops=Int(n)/2;var stack=InlineArray[Int64,256](fill=0);var top=0;var sum:Int64=0
    for i in range(ops):
        let op=v[2*i];let x=v[2*i+1];var obs:Int64=0;var returns=True
        if op==0:
            if x< -1000000 or x>1000000 or top==256:return -1
            stack[top]=x;top+=1;returns=False
        elif op==1:
            if x!=0 or top==0:return -1
            top-=1;obs=stack[top]
        elif op==2:
            if x!=0 or top==0:return -1
            obs=stack[top-1]
        elif op==3:
            if x!=0:return -1
            obs=1 if top==0 else 0
        else:return -1
        if returns:sum+=Int64(i+1)*(obs+1000000)
    for i in range(top):sum+=Int64(ops+i+1)*(stack[i]+1000000)
    return sum
