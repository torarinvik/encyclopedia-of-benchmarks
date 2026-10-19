from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sir")
fn sir(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=6:return -1
    let s=a[0];let i=a[1];let r=a[2];let beta=a[3];let k=a[4];let t=a[5]
    if not (s>=0.0 and s<=1000000.0 and i>=0.0 and i<=1000000.0 and r>=0.0 and r<=1000000.0 and beta>=0.0 and beta<=0.001 and k>=0.0 and k<=1.0 and t>=0.0 and t<=140.0):return -1
    let ds=((-beta)*s)*i;let di=((beta*s)*i)-(k*i);let dr=k*i
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<3:return -2
    o[0]=ds;o[1]=di;o[2]=dr;return 3
