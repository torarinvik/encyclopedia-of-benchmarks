from std.math import atan2, sqrt

@export("cartesian_to_polar")
fn cartesian_to_polar(x: Float64, y: Float64, component: Float64) abi("C") -> Float64:
    if x != x or y != y or (component != 0.0 and component != 1.0) or x < -1000000.0 or x > 1000000.0 or y < -1000000.0 or y > 1000000.0: return -1.0e300
    if component == 0.0: return sqrt(x * x + y * y)
    if x == 0.0 and y == 0.0: return 0.0
    return atan2(y, x)
