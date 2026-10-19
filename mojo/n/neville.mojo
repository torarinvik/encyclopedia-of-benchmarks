from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("neville")
fn neville(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>34 or a[0]<1 or a[0]>16 or n!=c_size_t(2+2*a[0]) or a[1]< -1000000 or a[1]>1000000:return -1.0e300
    let count=Int(a[0]);var x=InlineArray[Float64,16]();var p=InlineArray[Float64,16]()
    for i in range(count):
        let xi=a[2+2*i];let yi=a[3+2*i]
        if xi< -1000000 or xi>1000000 or yi< -1000000 or yi>1000000:return -1.0e300
        for j in range(i):if a[2+2*j]==xi:return -1.0e300
        x[i]=Float64(xi);p[i]=Float64(yi)
    let t=Float64(a[1])
    for k in range(1,count):
        for i in range(count-k):p[i]=((t-x[i+k])*p[i]+(x[i]-t)*p[i+1])/(x[i]-x[i+k])
    return p[0]
