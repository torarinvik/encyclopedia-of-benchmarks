from std.math import isfinite,pow
fn oom_exp(x:Float64)->Int:
    if x==0:return 0
    if x==1:return 3
    if x==2:return 6
    if x==3:return 9
    if x==4:return 12
    if x==5:return 15
    if x==6:return 18
    if x==7:return 21
    if x==8:return 24
    return -1
@export("order_of_magnitude_conversion")
fn order_of_magnitude_conversion(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or value < -1.0e100 or value>1.0e100:return -1.0
    let a=oom_exp(from);let b=oom_exp(to)
    if a<0 or b<0:return -1.0
    return value*pow(10.0,Float64(a-b))
