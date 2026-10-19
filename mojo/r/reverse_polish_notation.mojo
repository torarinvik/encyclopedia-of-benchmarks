from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("reverse_polish_notation")
fn reverse_polish_notation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>255:return -1.0e300
    var stack=InlineArray[Float64,63](fill=0.0);var top=0;var pos=0;var tokens=0
    while pos<Int(n):
        let start=pos
        while pos<Int(n) and v[pos]!=32:pos+=1
        let len=pos-start;if len==0:return -1.0e300
        tokens+=1;if tokens>63:return -1.0e300
        let c=Int(v[start])
        if len==1 and (c==43 or c==45 or c==42 or c==47):
            if top<2:return -1.0e300
            let a=stack[top-1];let b=stack[top-2];var r:Float64=0.0
            if c==43:r=a+b
            elif c==45:r=a-b
            elif c==42:r=a*b
            else:if a==0.0:return -1.0e300;r=b/a
            if r>1.0e200 or r< -1.0e200:return -1.0e300
            stack[top-2]=r;top-=1
        else:
            var i=start;var sign=1;var value:Float64=0.0
            if v[i]==45:sign= -1;i+=1
            elif v[i]==43:i+=1
            if i==pos:return -1.0e300
            while i<pos:
                if v[i]<48 or v[i]>57:return -1.0e300
                value=value*10.0+Float64(v[i]-48);if value>1000000.0:return -1.0e300;i+=1
            if top>=63:return -1.0e300
            stack[top]=Float64(sign)*value;top+=1
        if pos<Int(n):pos+=1
    if top!=1:return -1.0e300
    return stack[0]
