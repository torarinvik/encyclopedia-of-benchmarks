from math import floor, pow
fn sin_degrees_round10(x:Float64)->Float64:
    let bits=bitcast[UInt64](x)
    let negative=(bits>>UInt(63))!=0
    let exponent=Int((bits>>UInt(52))&UInt64(2047))
    let fraction=bits&UInt64(4503599627370495)
    if exponent==0:
        return -0.0 if negative else 0.0
    let e=exponent-1023
    let significand=fraction|UInt64(4503599627370496)
    let product=UInt128(significand)*UInt128(10000000000)
    var rounded:UInt128=0
    if e>=52:
        rounded=product<<UInt(e-52)
    else:
        let shift=52-e
        if shift<128:
            let denominator=UInt128(1)<<UInt(shift)
            var quotient=product>>UInt(shift)
            let remainder=product&(denominator-UInt128(1))
            let halfway=denominator>>UInt(1)
            if remainder>halfway or (remainder==halfway and (quotient&UInt128(1))!=0):quotient+=UInt128(1)
            rounded=quotient
    let integer=Int64(rounded)
    let signed= -integer if negative else integer
    return Float64(signed)/10000000000.0
@export("sin_degrees")
fn sin_degrees(x:Float64) abi("C")->Float64:
    if not (x>=-1000000.0 and x<=1000000.0):return -1.0
    let d=x-floor(x/360.0)*360.0;let r=d*(3.141592653589793/180.0)
    var result=r;var sign=-1.0;var power=3
    for _ in range(18):
        var fact=1.0
        for f in range(2,power+1):fact*=Float64(f)
        result+=sign*pow(r,Float64(power))/fact;sign = -sign;power+=2
    return sin_degrees_round10(result)
