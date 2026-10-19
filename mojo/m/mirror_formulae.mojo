from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("mirror_formulae")
fn mirror_formulae(a:Float64,b:Float64,op:Float64) abi("C")->Float64:
    if not isfinite(a) or not isfinite(b) or a==0.0 or b==0.0 or abs(a)<1e-6 or abs(b)<1e-6 or abs(a)>1e6 or abs(b)>1e6:return -1.0e300
    if op==0.0:
        let den=1.0/a+1.0/b
        return -1.0e300 if den==0.0 else 1.0/den
    if op==1.0:
        let den=1.0/a-1.0/b
        return -1.0e300 if den==0.0 else 1.0/den
    if op==2.0:
        let den=1.0/a-1.0/b
        return -1.0e300 if den==0.0 else 1.0/den
    return -1.0e300
