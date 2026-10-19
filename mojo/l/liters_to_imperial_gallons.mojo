from std.math import isfinite
@export("liters_to_imperial_gallons")
fn liters_to_imperial_gallons(x:Float64) abi("C")->Float64:
    if not isfinite(x) or x < -1.0e100 or x>1.0e100:return -1.0e300
    return x/4.54609
