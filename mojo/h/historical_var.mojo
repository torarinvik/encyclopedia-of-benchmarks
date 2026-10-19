from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("historical_var")
fn historical_var(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<24:return -1
    let cnt=a[3]
    if cnt<20.0 or cnt>64.0 or Float64(Int(cnt))!=cnt or n!=c_size_t(4+Int(cnt)) or a[0]<100.0 or a[0]>1000000.0 or a[1]<0.5 or a[1]>0.95 or a[2]<1.0 or a[2]>10.0:return -1
    let k=Int((1.0-a[1])*cnt);if k<1:return -1
    var r=InlineArray[Float64,64](fill=0)
    for i in range(Int(cnt)):
        r[i]=a[4+i];if r[i]< -0.25 or r[i]>0.25:return -1
    for i in range(Int(cnt)):for j in range(i+1,Int(cnt)):if r[i]>r[j]:let t=r[i];r[i]=r[j];r[j]=t
    let value= -r[k-1]*a[0]*sqrt(a[2])
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=value;return 1
