from std.math import floor,isfinite
fn round_even_area(x:Float64)->Float64:
    if x>=9007199254740992.0:return x
    let lo=floor(x);let fraction=x-lo;let odd=lo-2.0*floor(lo/2.0)!=0.0
    if fraction>0.5 or (fraction==0.5 and odd):return lo+1.0
    return lo
@export("orbital_capture_area")
fn orbital_capture_area(r:Float64) abi("C")->Float64:
    if not isfinite(r) or r<0 or r>1.0e10:return -1.0e300
    return round_even_area(3.14159265358979323846*r*r)
