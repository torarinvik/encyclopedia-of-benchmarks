from std.math import floor, fma
fn round_even3(x:Float64)->Float64:
    let scaled=x*1000.0;let low=floor(scaled);let mid=low+0.5;let side=fma(x,1000.0,-mid);var rounded=Int64(low)
    if side>0.0 or (side==0.0 and rounded%2!=0):rounded+=1
    return Float64(rounded)/1000.0
@export("speed_conversions")
fn speed_conversions(speed:Float64,route:Float64) abi("C")->Float64:
    if speed<0.0 or speed>1000000.0 or route<0.0 or route>15.0 or route!=Float64(Int(route)):return -1.0
    let f=InlineArray[Float64,4](1.0,3.6,1.609344,1.852);let inv=InlineArray[Float64,4](1.0,0.277777778,0.621371192,0.539956803)
    let r=Int(route);return round_even3((speed*f[r/4])*inv[r%4])
