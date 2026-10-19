from std.math import log, exp, floor, ceil, trunc
@export("powvialogarithm")
fn powvialogarithm(base:Float64,exponent:Float64) abi("C")->Float64:
    if base< -4 or base>4 or exponent< -8 or exponent>8 or trunc(base)!=base or trunc(exponent)!=exponent or (base==0 and exponent<=0) or (base==2 and exponent== -1) or (base== -2 and exponent== -1):return -1.0e300
    if base==0:return -0.0 if base<0 and Int(exponent)%2!=0 else 0.0
    let sign= -1.0 if base<0 and Int(exponent)%2!=0 else 1.0
    let value=exp(exponent*log(if base<0:-base else:base))*sign
    return floor(value+0.5) if value>=0 else ceil(value-0.5)
