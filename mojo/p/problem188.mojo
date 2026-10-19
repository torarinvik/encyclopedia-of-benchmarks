fn p188_modexpt(base:Int64,exponent:Int64,modulus:Int64)->Int64:
    if exponent==1:return base
    if exponent%2==0:
        let half=p188_modexpt(base,exponent//2,modulus)%modulus
        return (half*half)%modulus
    return (base*p188_modexpt(base,exponent-1,modulus))%modulus
@export("problem188")
fn problem188(base:Int64,height:Int64,digits:Int64) abi("C")->Int64:
    if base<1 or base>1000000000 or base%10==0 or height<1 or height>10000 or digits<1 or digits>8:return -1
    var modulus=Int64(1)
    for _ in range(Int(digits)):modulus*=10
    var result=base
    for _ in range(1,Int(height)):result=p188_modexpt(base,result,modulus)
    return result
