from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("temperature_conversions")
fn temperature_conversions(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>3:return -1.0e300
    let op=a[0];let micro=a[1]
    if n!=2 or op<0 or op>4 or micro< -1000000000000 or micro>1000000000000:return -1.0e300
    let t=Float64(micro)/1000000.0
    if op==0:
        if micro%5000000!=0:return -1.0e300
        return Float64(9*(micro/5000000)+32)
    if op==1:
        if (micro-32000000)%9000000!=0:return -1.0e300
        return Float64(5*((micro-32000000)/9000000))
    if op==2:
        if micro%1000000!=0:return -1.0e300
        return t+273.15
    if op==3:
        if (micro-273150000)%1000000!=0:return -1.0e300
        return t-273.15
    if (micro-273150000)%5000000!=0:return -1.0e300
    return Float64(9*((micro-273150000)/5000000)+32)
