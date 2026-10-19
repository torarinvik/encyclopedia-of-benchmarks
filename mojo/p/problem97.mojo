fn p97_mul(left_in:Int64,right_in:Int64,modulus:Int64)->Int64:
    var left=left_in;var right=right_in;var result=Int64(0)
    while right>0:
        if right%2!=0:result=(result+left)%modulus
        left=(left+left)%modulus;right//=2
    return result
@export("problem97")
fn problem97(digits:Int64) abi("C")->Int64:
    if digits<0 or digits>18:return -1
    var modulus=Int64(1)
    for _ in range(Int(digits)):modulus*=10
    var power=Int64(1)%modulus;var base=Int64(2)%modulus;var exponent=Int64(7830457)
    while exponent>0:
        if exponent%2!=0:power=p97_mul(power,base,modulus)
        base=p97_mul(base,base,modulus);exponent//=2
    return (p97_mul(28433,power,modulus)+1)%modulus
