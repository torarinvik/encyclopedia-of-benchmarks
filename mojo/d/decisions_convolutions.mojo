from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("decisions_convolutions")
fn decisions_convolutions(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3:return -1
    let method=input[0];let nd=input[1];let md=input[2]
    if (method!=0 and method!=1) or nd<1 or nd>64 or md<1 or md>16:return -1
    let n=Int(nd);let m=Int(md)
    if length!=c_size_t(3+m+n*m):return -1
    for i in range(m):
        if input[3+i]< -100000 or input[3+i]>100000:return -1
    for i in range(n*m):
        if input[3+m+i]< -100000 or input[3+m+i]>100000:return -1
    var best:Int64=0;var best_index=0
    for i in range(n):
        var score:Int64=0
        for j in range(m):
            let product=input[3+m+i*m+j]*input[3+j]
            if method==0:score+=product
            elif j==0 or product<score:score=product
        if i==0 or score>best:best=score;best_index=i
    return Int64(best_index)
