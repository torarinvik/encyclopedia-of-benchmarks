from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("xs3_conversion")
fn xs3_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let direction=v[0];var value=v[1]
    if direction==0:
        if value<0 or value>2147483647:return -1
        var decoded:Int64=0;var multiplier:Int64=1
        while value>0:
            let nibble=value&15
            if nibble<3 or nibble>12:return -1
            decoded+=(nibble-3)*multiplier;multiplier*=10;value=value>>4
        return decoded
    if direction==1:
        if value<0 or value>9999999:return -1
        var encoded:Int64=0;var shift=0
        while value>0:
            let digit=value%10+3
            encoded=encoded|(digit<<(shift*4));value/=10;shift+=1
        return encoded
    return -1
