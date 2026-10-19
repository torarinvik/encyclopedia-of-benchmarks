from std.math import isfinite
@export("length_conversion")
fn length_conversion(value:Float64,from_unit:Float64,to_unit:Float64) abi("C")->Float64:
    if not isfinite(value) or value < -1.0e6 or value > 1.0e6:return -1.0e300
    if not(from_unit==0.0 or from_unit==1.0 or from_unit==2.0 or from_unit==3.0) or not(to_unit==0.0 or to_unit==1.0 or to_unit==2.0 or to_unit==3.0):return -1.0e300
    let a=if from_unit==0.0:0.001 elif from_unit==1.0:0.01 elif from_unit==2.0:1.0 else:1000.0
    let b=if to_unit==0.0:0.001 elif to_unit==1.0:0.01 elif to_unit==2.0:1.0 else:1000.0
    return (value*a)/b
