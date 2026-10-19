from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime DIV_INVALID:Int64= -2147483649
@export("divide_two_integers")
fn divide_two_integers(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return DIV_INVALID
    let dividend=values[0];let divisor=values[1]
    if dividend< -2147483648 or dividend>2147483647 or divisor< -2147483648 or divisor>2147483647 or divisor==0:return DIV_INVALID
    let remaining0=dividend if dividend>=0 else -dividend;let divisor_mag=divisor if divisor>=0 else -divisor
    var remaining=remaining0;var quotient:Int64=0
    var shift=31
    while shift>=0:
        if divisor_mag<=(remaining>>UInt(shift)):remaining-=divisor_mag<<UInt(shift);quotient+=Int64(1)<<UInt(shift)
        shift-=1
    let negative=(dividend<0)!=(divisor<0)
    if negative:return -2147483648 if quotient==2147483648 else -quotient
    return 2147483647 if quotient>2147483647 else quotient
