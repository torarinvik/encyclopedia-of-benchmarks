from std.math import pow
@export("ordinary_annuity_future_value")
fn ordinary_annuity_future_value(payment:Float64,payments:Float64,rate:Float64) abi("C")->Float64:
    let factor=(pow(1.0+rate,payments)-1.0)/rate
    return payment*factor
