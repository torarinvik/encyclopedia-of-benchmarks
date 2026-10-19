from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("euler_problem_7")
fn euler_problem_7(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<1 or input[0]>10001:return -1
    let target=Int(input[0]);var count=0;var candidate=1
    while count<target:
        candidate+=1;var prime=True
        for d in range(2,candidate):
            if d*d>candidate:break
            if candidate%d==0:prime=False;break
        if prime:count+=1
    return candidate
