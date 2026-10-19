from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_means_rust")
fn k_means_rust(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=10 or a[0]!=4 or a[1]<1 or a[1]>16:return -1
    for i in range(4):if a[2+i]<0 or a[2+i]>9007199254740991:return -1
    if a[3]!=0 or a[5]!=0 or a[2]==a[4]:return -1
    var x=InlineArray[Float64,4](fill=0.0)
    for i in range(4):
        x[i]=Float64(a[6+i])
        if x[i]< -16.0 or x[i]>16.0 or (i>0 and x[i]<=x[i-1]):return -1
    if x[1]>=0.0 or x[2]<=1.0:return -1
    let denom=9007199254740992.0;var c0=Float64(a[2])/denom;var c1=Float64(a[4])/denom;var labels=InlineArray[Int,4](fill=0)
    for iteration in range(Int(a[1])):
        var s0=0.0;var s1=0.0;var n0=0;var n1=0
        for i in range(4):
            let d0=(x[i]-c0)*(x[i]-c0);let d1=(x[i]-c1)*(x[i]-c1);labels[i]=1 if d1<d0 else 0
            if labels[i]==0:s0+=x[i];n0+=1
            else:s1+=x[i];n1+=1
        if n0==0 or n1==0:return -1
        c0=s0/Float64(n0);c1=s1/Float64(n1)
    var result:Int64=0
    for i in range(4):result|=Int64(labels[i])<<i
    return result
