from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ms_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v)
    for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("min_stack")
fn min_stack(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>513:return -1
    let count=a[0];if count<0 or count>256:return -1
    var ops=InlineArray[Int64,256]();var vals=InlineArray[Int64,256]();var p=1;var q=0
    for i in range(Int(count)):
        if p>=Int(n):return -1
        let op=a[p];p+=1
        if op<0 or op>3:return -1
        ops[i]=op
        if op==0:
            if p>=Int(n):return -1
            vals[i]=a[p];p+=1;if vals[i]< -2147483648 or vals[i]>2147483647:return -1
        elif op==2 or op==3:q+=1
    if p!=Int(n):return -1
    let bytes=(1+3*q)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    ms_put(o,0,Int64(q));var stack=InlineArray[Int64,256]();var mins=InlineArray[Int64,256]();var d=0;var outp=8
    for i in range(Int(count)):
        let op=ops[i]
        if op==0:stack[d]=vals[i];mins[d]=vals[i] if d==0 or vals[i]<mins[d-1] else mins[d-1];d+=1
        elif op==1:if d>0:d-=1
        else:
            let exc=1 if d==0 else 0
            let value=0 if d==0 else (stack[d-1] if op==2 else mins[d-1])
            ms_put(o,outp,op);ms_put(o,outp+8,exc);ms_put(o,outp+16,value);outp+=24
    return Int64(bytes)
