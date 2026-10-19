from std.math import isfinite,sin,sqrt
@export("line_length")
fn line_length(a:Float64,b:Float64,steps:Float64) abi("C")->Float64:
    if not isfinite(a) or not isfinite(b) or not isfinite(steps) or a < -10.0 or a>10.0 or b < -10.0 or b>10.0 or a>b or steps<1.0 or steps>10000.0:return -1.0e300
    let count=Int(steps)
    if Float64(count)!=steps:return -1.0e300
    var x=a;var fx=sin(10.0*a);var total=0.0
    for _ in range(count):
        let nx=(b-a)/Float64(count)+x;let fy=sin(10.0*nx);let dx=nx-x;let dy=fy-fx
        total+=sqrt(dx*dx+dy*dy);x=nx;fx=fy
    return total
