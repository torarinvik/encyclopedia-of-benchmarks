from std.math import floor,isfinite,sqrt
fn round_even_radius(x:Float64)->Float64:
    if x>=9007199254740992.0:return x
    let lo=floor(x);let frac=x-lo;let odd=lo-2.0*floor(lo/2.0)!=0.0
    if frac>0.5 or (frac==0.5 and odd):return lo+1.0
    return lo
@export("orbital_capture_radii")
fn orbital_capture_radii(radius:Float64,mass:Float64,velocity:Float64) abi("C")->Float64:
    if not isfinite(radius) or not isfinite(mass) or not isfinite(velocity) or radius<1.0e-6 or radius>1.0e10 or mass<0 or mass>2.0e30 or velocity<1.0e6 or velocity>299792458.0:return -1.0e300
    let ev2=(2.0*6.67430e-11*mass)/radius
    let capture=radius*sqrt(1.0+ev2/(velocity*velocity))
    return round_even_radius(capture)
