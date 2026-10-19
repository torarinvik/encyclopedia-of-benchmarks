from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("kendall_rank_correlation_coefficient")
fn kendall_rank_correlation_coefficient(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>257:return -1.0e300
    let count=a[0]
    if count<2 or count>128 or n!=c_size_t(1+2*Int(count)):return -1.0e300
    for i in range(1,Int(n)):if a[i]<-1000000 or a[i]>1000000:return -1.0e300
    var c:Int64=0;var d:Int64=0;var tx:Int64=0;var ty:Int64=0
    for i in range(Int(count)):
        for j in range(i+1,Int(count)):
            let x1=a[1+i];let x2=a[1+j];let y1=a[1+Int(count)+i];let y2=a[1+Int(count)+j]
            if x1==x2:tx+=1
            if y1==y2:ty+=1
            if (x1<x2 and y1<y2) or (x1>x2 and y1>y2):c+=1
            elif (x1<x2 and y1>y2) or (x1>x2 and y1<y2):d+=1
    let pairs=Float64(count*(count-1)//2);let den=sqrt((pairs-Float64(tx))*(pairs-Float64(ty)))
    if den==0.0:return -1.0e300
    return Float64(c-d)/den
