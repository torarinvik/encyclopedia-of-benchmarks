@export("exponentiation")
fn exponentiation(base:Int64,exponent:Int64) abi("C")->Int64:
    if base<0 or base>255 or exponent<0 or exponent>7:return -1
    var result:Int64=1
    for i in range(Int(exponent)):result*=base
    return result
