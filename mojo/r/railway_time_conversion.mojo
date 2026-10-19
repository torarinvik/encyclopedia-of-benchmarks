from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn isdigit64(x:Int64)->Bool:return x>=48 and x<=57
@export("railway_time_conversion")
fn railway_time_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=11 or v[0]!=10:return -1
    if v[3]!=58 or v[6]!=58 or not ((v[9]==65 and v[10]==77) or (v[9]==80 and v[10]==77)) or not isdigit64(v[1]) or not isdigit64(v[2]) or not isdigit64(v[4]) or not isdigit64(v[5]) or not isdigit64(v[7]) or not isdigit64(v[8]):return -1
    let hour=(v[1]-48)*10+v[2]-48;let minute=(v[4]-48)*10+v[5]-48;let second=(v[7]-48)*10+v[8]-48
    if hour<1 or hour>12 or minute>59 or second>59:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let hour24=hour%12+(if v[9]==80:12 else:0)
    o[0]=UInt8(48+hour24/10);o[1]=UInt8(48+hour24%10);o[2]=58;o[3]=UInt8(v[4]);o[4]=UInt8(v[5]);o[5]=58;o[6]=UInt8(v[7]);o[7]=UInt8(v[8]);return 8
