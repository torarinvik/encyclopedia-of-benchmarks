from std.math import asin, fabs, sin

@export("snell_law")
fn snell_law(n1:Float64,n2:Float64,theta1:Float64) abi("C")->Float64:
    if n1!=n1 or n2!=n2 or theta1!=theta1 or n1<0.5 or n1>2.5 or n2<0.5 or n2>2.5 or theta1< -1.5707963267948966 or theta1>1.5707963267948966:return -1.0e300
    let ratio=n1/n2;let sine=ratio*sin(theta1)
    if fabs(sine)>1.0:return -1.0e300
    return asin(sine)
