from std.math import atan2,fabs,isfinite,sqrt,signbit,trunc
fn rtp_round(x:Float64)->Float64:
    if x==0:return x
    let scaled=x*100.0;let units=if scaled<0:trunc(scaled-0.5) else:trunc(scaled+0.5)
    if units==0 and signbit(x):return -0.0
    return units/100.0
@export("rectangular_to_polar")
fn rectangular_to_polar(real:Float64,imag:Float64,component:Float64) abi("C")->Float64:
    if not isfinite(real) or not isfinite(imag) or not isfinite(component) or real < -1.0e6 or real>1.0e6 or imag < -1.0e6 or imag>1.0e6 or (component!=0 and component!=1):return -1.0e300
    if component==0:return rtp_round(sqrt(real*real+imag*imag))
    return rtp_round(atan2(imag,real)*57.2957795130823208768)
