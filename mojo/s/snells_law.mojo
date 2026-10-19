from std.math import asin, fabs, floor, sin

fn snl_round_two_even(value:Float64)->Float64:
    let scaled=value*100.0;let lower=floor(scaled);let fraction=scaled-lower
    let integer=Int64(lower)
    var rounded=integer
    if fraction>0.5 or (fraction==0.5 and integer%2!=0):rounded+=1
    return Float64(rounded)/100.0

@export("snells_law")
fn snells_law(n1:Float64,n2:Float64,angle:Float64) abi("C")->Float64:
    if !(n1>=0.5 and n1<=2.5) or !(n2>=0.5 and n2<=2.5) or !(angle>= -90.0 and angle<=90.0):return -1.0e300
    let radians=angle*(3.141592653589793238462643383279502884/180.0)
    let sine=(n1/n2)*sin(radians)
    let scale=fabs(sine) if fabs(sine)>1.0 else 1.0
    if fabs(sine-1.0)<=1.0e-9*scale:return 90.0
    if fabs(sine+1.0)<=1.0e-9*scale:return -90.0
    if !(sine>= -1.0 and sine<=1.0):return -1.0e300
    return snl_round_two_even(asin(sine)*(180.0/3.141592653589793238462643383279502884))
