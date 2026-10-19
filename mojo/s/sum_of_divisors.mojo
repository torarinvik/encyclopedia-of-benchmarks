@export("sum_of_divisors")
fn sum_of_divisors(n: Int64) abi("C") -> Int64:
    if n < 1 or n > 1000000: return -1
    var remaining=n; var sigma:Int64=1; var factor:Int64=2
    while factor <= remaining / factor:
        if remaining % factor == 0:
            var power:Int64=1; var geom:Int64=1
            while remaining % factor == 0:
                remaining /= factor
                power *= factor
                geom += power
            sigma *= geom
        factor += 1
    if remaining > 1: sigma *= remaining + 1
    return sigma
