from std.math import isfinite
@export("ohms_law")
fn ohms_law(voltage:Float64,current:Float64,resistance:Float64) abi("C")->Float64:
    if not isfinite(voltage) or not isfinite(current) or not isfinite(resistance) or voltage < -1000 or voltage>1000 or current < -1000 or current>1000 or resistance<0 or resistance>1000 or Float64(Int(voltage))!=voltage or Float64(Int(current))!=current or Float64(Int(resistance))!=resistance:return -1.0e300
    let zeros=Int(voltage==0.0)+Int(current==0.0)+Int(resistance==0.0)
    if zeros!=1:return -1.0e300
    if voltage==0.0:return current*resistance
    if current==0.0:return voltage/resistance
    return voltage/current
