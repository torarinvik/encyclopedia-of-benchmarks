from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("temperature_converter")
fn temperature_converter(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>3:return -1.0e300
    let op=a[0];let micro=a[1]
    if n!=2 or op<0 or op>5 or micro< -1000000000000 or micro>1000000000000:return -1.0e300
    let t=Float64(micro)/1000000.0
    if op==0:return t*1.8+32.0
    if op==1:return t+273.15
    if op==2:return (t-32.0)*5.0/9.0
    if op==3:return (t-32.0)*5.0/9.0+273.15
    if op==4:return t-273.15
    return (t-273.15)*1.8+32.0
