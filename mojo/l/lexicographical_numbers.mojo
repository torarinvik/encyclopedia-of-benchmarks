from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("lexicographical_numbers")
fn lexicographical_numbers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>4096:return -1
    var stack=InlineArray[Int64,4112](fill=0);var top=1;stack[0]=1;var index:Int64=0;var checksum:Int64=0
    while top>0:
        top-=1;let x=stack[top]
        if x<=v[0]:
            index+=1;checksum+=index*x
            if x%10!=9:stack[top]=x+1;top+=1
            stack[top]=x*10;top+=1
    return checksum
