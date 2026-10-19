from std.math import isfinite
@export("time_and_half_pay")
fn time_and_half_pay(hours:Float64,rate:Float64,threshold:Float64) abi("C")->Float64:
    if not isfinite(hours) or not isfinite(rate) or not isfinite(threshold) or hours<0.0 or hours>1000.0 or rate<0.0 or rate>1000.0 or threshold<0.0 or threshold>1000.0:return -1.0e300
    let normal=hours*rate;var overtime=hours-threshold
    if overtime<0.0:overtime=0.0
    let overtime_pay=overtime*rate/2.0
    return normal+overtime_pay
