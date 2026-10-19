from std.math import isfinite
@export("ncr_combinations")
fn ncr_combinations(total:Float64,choose:Float64) abi("C")->Float64:
    if not isfinite(total) or not isfinite(choose) or total<0.0 or total>20.0 or choose<0.0 or choose>12.0 or Float64(Int64(choose))!=choose:return -1.0e300
    let c=Int(choose);var numerator:Float64=1.0
    for i in range(c):numerator*=total-Float64(i)
    var denominator:Float64=1.0
    for i in range(2,c+1):denominator*=Float64(i)
    return numerator/denominator
