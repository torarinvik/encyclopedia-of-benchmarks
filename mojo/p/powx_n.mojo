fn px_positive(base:Float64,exp:Int64)->Float64:
    if exp==0:return 1.0
    var mask=Int64(1)
    while mask<=exp//2:mask<<=1
    var result=base;mask>>=1
    while mask!=0:
        result*=result
        if (exp&mask)!=0:result*=base
        mask>>=1
    return result
@export("powx_n")
fn powx_n(base:Float64,exponent:Int32) abi("C")->Float64:
    let e=Int64(exponent)
    if e==0:return 1.0
    if e== -2147483648:return 1.0/(px_positive(base,2147483647)*base)
    if e<0:return 1.0/px_positive(base,-e)
    return px_positive(base,e)
