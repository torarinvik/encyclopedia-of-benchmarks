from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_means_julia")
fn k_means_julia(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4:return -1
    let count=a[0];if count<3 or count>8 or n!=c_size_t(count+1):return -1
    var x=InlineArray[Float64,8](fill=0.0)
    for i in range(Int(count)):
        if a[i+1]< -16 or a[i+1]>16 or (i>0 and a[i+1]<=a[i]):return -1
        x[i]=Float64(a[i+1])
    var c0=x[0];var c1=x[Int(count)//2]
    for iteration in range(64):
        var s0=0.0;var s1=0.0;var n0=0;var n1=0
        for i in range(Int(count)):
            if abs(x[i]-c1)<abs(x[i]-c0):s1+=x[i];n1+=1
            else:s0+=x[i];n0+=1
        if n0==0 or n1==0:return -1
        let next0=s0/Float64(n0);let next1=s1/Float64(n1)
        if next0==c0 and next1==c1:
            return (Int64(next0*256.0)+4097)*8194+(Int64(next1*256.0)+4097)
        c0=next0;c1=next1
    return -2
