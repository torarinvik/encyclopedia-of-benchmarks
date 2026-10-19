from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt, floor

fn escape_round_three(value:Float64)->Float64:
    let scaled=value*1000.0;let lower=floor(scaled);let frac=scaled-lower
    var rounded=Int64(lower)
    if frac>0.5 or (frac==0.5 and rounded%2!=0):rounded+=1
    return Float64(rounded)/1000.0
@export("escape_velocity")
fn escape_velocity(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1.0e300
    let mass=values[0];let radius=values[1]
    if mass<0 or mass>1000000000000000 or radius<1 or radius>1000000000:return -1.0e300
    return escape_round_three(sqrt(2.0*6.67430e-11*Float64(mass)/Float64(radius)))
