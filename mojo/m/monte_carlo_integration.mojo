from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("monte_carlo_integration")
fn monte_carlo_integration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>12:return -1.0e300
    let count=v[2];if count<1 or count>16 or Int(n)!=3+Int((count+1)/2):return -1.0e300
    if v[0] < -10000000 or v[0]>10000000 or v[1] < -10000000 or v[1]>10000000 or v[0]>=v[1]:return -1.0e300
    for i in range(3,Int(n)):if v[i]<0 or v[i]>999999:return -1.0e300
    let a=Float64(v[0])/1000000.0;let b=Float64(v[1])/1000000.0;let interval=b-a;var total=0.0
    for i in range(Int(count/2)):
        let u=Float64(v[3+i])/1000000.0;let x1=a+u*interval;let x2=a+(1.0-u)*interval;total+=x1*x1;total+=x2*x2
    if count%2==1:let u=Float64(v[3+Int(count/2)])/1000000.0;let x=a+u*interval;total+=x*x
    return interval*total/Float64(count)
