from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn decimal_fraction_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt64(value)
    for i in range(8):out[offset+i]=UInt8((bits>>UInt(i*8))&255)
fn decimal_fraction_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("decimal_to_fraction")
fn decimal_to_fraction(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1
    let mantissa=input[0];let places=input[1]
    if places<0 or places>4:return -1
    var scale:Int64=1;var pow5:Int64=1
    for i in range(Int(places)):scale*=10;pow5*=5
    if mantissa< -1000000*scale or mantissa>1000000*scale or mantissa%pow5!=0:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16:return -2
    let decimal=Float64(mantissa)/Float64(scale)
    var numerator:Int64=0;var denominator:Int64=1
    if Float64(Int64(decimal))==decimal:numerator=Int64(decimal)
    else:
        var digits=Int(places);var magnitude=mantissa
        if magnitude<0:magnitude= -magnitude
        while digits>0 and magnitude%10==0:magnitude/=10;digits-=1
        var multiplier:Float64=1.0
        for i in range(digits):multiplier*=10.0
        numerator=Int64(decimal*multiplier);denominator=1
        for i in range(digits):denominator*=10
        var absnum=numerator
        if absnum<0:absnum= -absnum
        let gcd=decimal_fraction_gcd(absnum,denominator)
        numerator/=gcd;denominator/=gcd
    decimal_fraction_put(out,0,numerator);decimal_fraction_put(out,8,denominator)
    return 16
