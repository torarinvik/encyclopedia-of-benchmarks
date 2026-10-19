from std.memory import ImmutAnyOrigin, UnsafePointer
@export("shear_stress")
fn shear_stress(stress:Float64,force:Float64,area:Float64) abi("C")->Float64:
    if stress<0 or stress>1000 or force<0 or force>1000 or area<0 or area>1000:return -1.0
    if Float64(Int64(stress))!=stress or Float64(Int64(force))!=force or Float64(Int64(area))!=area:return -1.0
    let zeros=Int(stress==0)+Int(force==0)+Int(area==0);if zeros!=1:return -1.0
    if stress==0:return force/area
    if force==0:return stress*area
    return force/stress
