from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem345")
fn problem345(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>226:return -1
    let n=input[0]
    if n<1 or n>15 or length!=c_size_t(n*n+1):return -1
    for i in range(1,Int(length)):if input[i]<0 or input[i]>1000:return -1
    let states=1<<Int(n);var best=InlineArray[Int64,32768](fill=-1);best[0]=0
    for mask in range(states):
        if best[mask]<0:continue
        var row=0;var m=mask
        while m>0:row+=m&1;m>>=1
        if row>=Int(n):continue
        for col in range(Int(n)):
            let bit=1<<col
            if mask&bit!=0:continue
            let next=mask|bit;let candidate=best[mask]+input[1+row*Int(n)+col]
            if candidate>best[next]:best[next]=candidate
    return best[states-1]
