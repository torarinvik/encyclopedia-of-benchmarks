from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("median_two_array")
fn median_two_array(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>259:return -1.0e300
    let a=v[0];let b=v[1]
    if a<0 or b<0 or a+b<1 or a+b>256 or Int(n)!=Int(a+b)+2:return -1.0e300
    let total=Int(a+b);let bs=Int(a)+2;var x=InlineArray[Int64,256](fill=0)
    for i in range(Int(a)):
        if v[i+2] < -1000000 or v[i+2] > 1000000 or (i>0 and v[i+1]>v[i+2]):return -1.0e300
        x[i]=v[i+2]
    for i in range(Int(b)):
        if v[bs+i] < -1000000 or v[bs+i] > 1000000 or (i>0 and v[bs+i-1]>v[bs+i]):return -1.0e300
        x[Int(a)+i]=v[bs+i]
    for i in range(1,total):
        let key=x[i];var j=i
        while j>0 and x[j-1]>key:x[j]=x[j-1];j-=1
        x[j]=key
    if total%2==1:return Float64(x[total//2])
    return (Float64(x[total//2-1])+Float64(x[total//2]))/2.0
