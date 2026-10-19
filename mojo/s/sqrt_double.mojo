from std.math import floor
fn bisect_sqrt(x:Float64)->Float64:
    if x>0.0 and x<1.0:return 1.0/bisect_sqrt(1.0/x)
    var low=0.0;var high=x
    while low<=high:
        let mid=(low+high)/2.0;let sq=mid*mid
        if sq>x:high=mid
        else:
            if x-sq<1e-12:return mid
            low=mid
    return -1.0
@export("sqrt_double")
fn sqrt_double(x:Float64) abi("C")->Float64:
    if x==0.0:return 0.0
    if x<1.0/256.0 or x>64.0:return -1.0
    return bisect_sqrt(x)
