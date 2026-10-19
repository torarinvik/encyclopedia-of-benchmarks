from std.math import isfinite
fn p58_prime(value:Int64)->Bool:
    if value<2:return False
    if value<4:return True
    if value%2==0 or value%3==0:return False
    var d=Int64(5)
    while d<=value//d:
        if value%d==0 or value%(d+2)==0:return False
        d+=6
    return True
@export("problem58")
fn problem58(ratio:Float64) abi("C")->Float64:
    if !isfinite(ratio) or ratio<0.1 or ratio>0.6:return -1.0
    var side=Int64(3);var prime_count=Int64(3)
    while Float64(prime_count)/Float64(2*side-1)>=ratio:
        let square=side*side;let step=side+1
        if p58_prime(square+step):prime_count+=1
        if p58_prime(square+2*step):prime_count+=1
        if p58_prime(square+3*step):prime_count+=1
        side+=2
    return Float64(side)
