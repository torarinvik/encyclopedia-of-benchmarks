from std.math import cos, abs, isfinite
@export("golden_search_extrema")
fn golden_search_extrema(id:Float64,left:Float64,right:Float64) abi("C")->Float64:
    if not isfinite(id) or not isfinite(left) or not isfinite(right) or (id!=0.0 and id!=1.0):return -1.0
    if id==0.0:
        if left<0.0 or left>4.0 or right<0.0 or right>4.0:return -1.0
    else:
        if left<2.0 or left>4.0 or right<2.0 or right>4.0:return -1.0
    var a=left;var b=right
    if a>b:let t=a;a=b;b=t
    if b-a<2.0e-7:return -1.0
    if id==0.0:
        if not (a<2.0 and 2.0<b):return -1.0
    elif not (a<3.14159265358979323846 and 3.14159265358979323846<b):return -1.0
    var mean=1.0e300;var previous=1.0e300;let phi=1.61803400516510009765625
    for i in range(128):
        if abs(b-a)<=1.0e-7:break
        previous=mean;let ratio=(b-a)/phi;let c=b-ratio;let d=a+ratio
        let fc=if id==0.0 then (c-2.0)*(c-2.0) else cos(c)
        let fd=if id==0.0 then (d-2.0)*(d-2.0) else cos(d)
        if fc<fd:b=d
        else:a=c
        mean=(a+b)/2.0
    return previous
