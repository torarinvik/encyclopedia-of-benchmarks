from std.math import floor
fn php_round2(x:Float64)->Float64:return floor(x*100.0+0.5)/100.0
@export("speed_conversion")
fn speed_conversion(speed:Float64,route:Float64) abi("C")->Float64:
    if speed<0.0 or speed>1000000.0 or route<0.0 or route>24.0 or route!=Float64(Int(route)):return -1.0
    let f=InlineArray[Float64,5](1.609344,1.0,3.6,1.097,1.852);let inv=InlineArray[Float64,5](0.6213712,1.0,0.277778,0.911344,0.539957)
    let r=Int(route);return php_round2((speed*f[r/5])*inv[r%5])
