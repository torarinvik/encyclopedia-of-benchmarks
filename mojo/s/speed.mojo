from std.ffi import c_size_t
from std.math import floor
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
fn round_speed(s:Float64)->Float64:
    if s==0.0:return s/1000.0
    let neg=s<0.0;let mag=if neg then -s else s;var r=Int64(mag)
    if mag-Float64(r)>=0.5:r+=1
    let x=Float64(r)/1000.0
    return if neg then -x else x
@export("speed")
fn speed(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return BAD
    let sm=v[0];let from=v[1];let to=v[2]
    if sm< -1000000000000000 or sm>1000000000000000 or from<0 or from>6 or to<0 or to>6:return BAD
    let to_kmh=InlineArray[Float64,7](1.0,3.6,1.609344,1.852,1.09728,1225.08,1079252848.8)
    let from_kmh=InlineArray[Float64,7](1.0,0.277777778,0.621371192,0.539956803,0.911344415,0.000816164,9.265669311e-10)
    let x=(Float64(sm)/1000000.0)*to_kmh[Int(from)];let y=x*from_kmh[Int(to)];let scaled=y*1000.0
    if scaled>9007199254740992.0 or scaled< -9007199254740992.0:return BAD
    return round_speed(scaled)
