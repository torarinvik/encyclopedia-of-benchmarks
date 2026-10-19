from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor
@export("temparature_conversion")
fn temparature_conversion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4:return -1.0e300
    let op=a[0];let micro=a[1];let digits=a[2]
    if op<0 or op>5 or micro< -1000000000000 or micro>1000000000000 or digits< -6 or digits>6 or n!=3:return -1.0e300
    let t=Float64(micro)/1000000.0;var x:Float64=0.0
    if op==0:x=t*1.8+32.0
    elif op==1:x=t+273.15
    elif op==2:x=(t-32.0)*5.0/9.0
    elif op==3:x=((t-32.0)*5.0/9.0)+273.15
    elif op==4:x=t-273.15
    else:x=((t-273.15)*1.8)+32.0
    var factor:Float64=1.0
    let magnitude=Int(digits if digits>=0 else -digits)
    for _ in range(magnitude): factor*=10.0
    let scaled=x*factor if digits>=0 else x/factor
    let lower=floor(scaled);let fraction=scaled-lower
    var rounded=lower
    if fraction>0.5: rounded=lower+1.0
    elif fraction==0.5 and Int64(lower)%2!=0: rounded=lower+1.0
    return rounded/factor if digits>=0 else rounded*factor
