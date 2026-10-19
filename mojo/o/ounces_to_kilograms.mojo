@export("ounces_to_kilograms")
fn ounces_to_kilograms(ounces:Float64) abi("C")->Float64:
    if ounces < -1000000.0 or ounces>1000000.0:return -1.0e300
    return (ounces*28.3498)/1000.0
