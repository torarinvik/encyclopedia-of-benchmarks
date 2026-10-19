from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import abs, isfinite, pow
@export("nth_root")
fn nth_root(radicand:Float64,index:Float64,tolerance:Float64) abi("C")->Float64:
    if not isfinite(radicand) or not isfinite(index) or not isfinite(tolerance) or radicand<0.5 or radicand>1000.0 or index<3.0 or index>8.0 or Float64(Int64(index))!=index or tolerance<1.0e-12 or tolerance>1.0e-3:return -1.0e300
    var new=radicand;var old=new+tolerance+0.1
    var rounds=0
    while tolerance<=abs(old-new) and rounds<1000:
        old=new
        let first=(index-1.0)/index*old
        let second=radicand/(index*pow(old,index-1.0))
        new=first+second;rounds+=1
    return new
