from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mst_put(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p+b]=UInt8((u>>(8*b))&255)
@export("min_stack_using_two_stacks")
fn min_stack_using_two_stacks(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>513 or v[0]<0 or v[0]>256:return -1
    let ops=Int(v[0]);var opcodes=InlineArray[Int64,256](fill=0);var operands=InlineArray[Int64,256](fill=0);var pos=1;var ec=0
    for i in range(ops):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos>=Int(n):return -1
            let x=v[pos];pos+=1
            if x < -2147483648 or x>2147483647:return -1
            operands[i]=x
        elif op==1 or op==2 or op==3:ec+=1
        else:return -1
        opcodes[i]=op
    if pos!=Int(n):return -1
    let bytes=(1+3*ec)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var stack=InlineArray[Int64,256](fill=0);var mins=InlineArray[Int64,256](fill=0);var depth=0;var md=0;var p=0
    mst_put(out,p,Int64(ec));p+=8
    for i in range(ops):
        let op=opcodes[i]
        if op==0:
            let x=operands[i];stack[depth]=x;depth+=1
            if md==0 or x<=mins[md-1]:mins[md]=x;md+=1
        elif op==1:
            var flag:Int64=0
            if depth==0:flag=1
            else:depth-=1;if stack[depth]==mins[md-1]:md-=1
            mst_put(out,p,1);mst_put(out,p+8,flag);mst_put(out,p+16,0);p+=24
        else:
            var flag:Int64=0;var value:Int64=0
            if depth==0:flag=1
            elif op==2:value=stack[depth-1]
            else:value=mins[md-1]
            mst_put(out,p,op);mst_put(out,p+8,flag);mst_put(out,p+16,value);p+=24
    return Int64(bytes)
