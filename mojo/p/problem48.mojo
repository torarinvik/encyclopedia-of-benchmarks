@export("problem48")
fn problem48(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    let modulus=Int64(10000000000);var total=Int64(0)
    for i in range(1,1001):
        var base=Int64(i);var exp=i;var value=Int64(1)
        while exp>0:
            if exp%2==1:value=(value*base)%modulus
            base=(base*base)%modulus;exp//=2
        total=(total+value)%modulus
    return total
