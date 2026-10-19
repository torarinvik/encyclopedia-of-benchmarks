from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("half_wave_rectifier")
fn half_wave_rectifier(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1.0e300
    for i in range(1,5):if a[i]< -1000000 or a[i]>1000000:return -1.0e300
    let op=a[0]
    if op==0:
        if a[1]<0 or a[2]<0 or a[3]<0 or (a[1]==0 and a[2]==0 and a[3]==0):return -1.0e300
        return Float64(a[4])/Float64(a[1]+a[2]+a[3])
    if op==1 or op==2:
        if a[2]!=0 or a[3]!=0 or a[4]!=0:return -1.0e300
        return Float64(a[1])*0.318
    if op==3:
        if a[2]<=0 or a[3]!=0 or a[4]!=0:return -1.0e300
        return Float64(a[1])/Float64(a[2])
    if op==4 or op==5:
        if a[2]!=0 or a[3]!=0 or a[4]!=0:return -1.0e300
        return Float64(a[1])/2.0
    return -1.0e300
