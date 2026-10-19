from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("schur_complement")
fn schur_complement(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1.0e300
    for i in range(3):if a[i]<-8 or a[i]>8:return -1.0e300
    for i in range(3,6):if a[i]<-100 or a[i]>100:return -1.0e300
    let det=a[0]*a[2]-a[1]*a[1]
    if det==0:return -1.0e300
    let i00=Float64(a[2])/Float64(det);let i01= -Float64(a[1])/Float64(det)
    let i10= -Float64(a[1])/Float64(det);let i11=Float64(a[0])/Float64(det)
    let l0=Float64(a[3])*i00+Float64(a[4])*i10
    let l1=Float64(a[3])*i01+Float64(a[4])*i11
    let q=l0*Float64(a[3])+l1*Float64(a[4])
    return Float64(a[5])-q
