comptime ARC_PI: Float64 = 3.141592653589793238462643383279502884

@export("arc_length")
fn arc_length(radius: Float64, angle: Float64, unit: Float64) abi("C") -> Float64:
    if unit == 0.0:
        return 2.0 * ARC_PI * radius * (angle / 360.0)
    return radius * angle
