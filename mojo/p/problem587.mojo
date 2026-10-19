from std.math import sqrt, asin, isfinite
fn p587_arc(point:Float64)->Float64:
    return ((1.0-2.0*point)*sqrt(point-point*point)+2.0*point+asin(sqrt(1.0-point)))/4.0
fn p587_area(n:Int)->Float64:
    let circles=Float64(n);let y=(circles+1.0-sqrt(2.0*circles))/(2.0*(circles*circles+1.0));let x=circles*y
    return x*y/2.0+p587_arc(0.5)-p587_arc(x)
@export("problem587")
fn problem587(fraction:Float64) abi("C")->Float64:
    let invalid=Float64(-1.0e300)
    if !isfinite(fraction) or fraction<0.001 or fraction>0.1:return invalid
    let l_area=(1.0-3.14159265358979323846/4.0)/4.0
    for n in range(1,100001):
        if p587_area(n)/l_area<fraction:return Float64(n)
    return invalid
