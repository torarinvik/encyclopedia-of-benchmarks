from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor
@export("temperature_conversion")
fn temperature_conversion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -9223372036854775808
    let op=a[0];let t=a[1]
    if op<0 or op>15 or t< -1000000 or t>1000000:return -9223372036854775808
    let x=Float64(t);var y:Float64=0.0
    if op==0:y=x*9.0/5.0+32.0
    elif op==1:y=x+273.15
    elif op==2:y=x*9.0/5.0+491.67
    elif op==3:y=(x-32.0)*5.0/9.0
    elif op==4:y=(x-32.0)*5.0/9.0+273.15
    elif op==5:y=x+459.67
    elif op==6:y=x-273.15
    elif op==7:y=(x-273.15)*9.0/5.0+32.0
    elif op==8:y=x*9.0/5.0
    elif op==9:y=(x-491.67)*5.0/9.0
    elif op==10:y=x-459.67
    elif op==11:y=x*5.0/9.0
    elif op==12:y=x*5.0/4.0
    elif op==13:y=x*9.0/4.0+32.0
    elif op==14:y=x*5.0/4.0+273.15
    else:y=x*9.0/4.0+32.0+459.67
    return Int64(floor(y+0.5))
