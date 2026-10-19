from std.math import atan2, cos, sin, sqrt

@export("coordinate_converter")
fn coordinate_converter(first: Float64, second: Float64, component: Float64) abi("C") -> Float64:
    if component == 0.0 or component == 1.0:
        if first != first or second != second or first < -1000000.0 or first > 1000000.0 or second < -1000000.0 or second > 1000000.0: return -1.0e300
        if component == 0.0: return sqrt(first * first + second * second)
        return atan2(second, first) * 57.2957795130823208768
    if component == 2.0 or component == 3.0:
        if first != first or second != second or first < 0.0 or first > 1000000.0 or second < -36000.0 or second > 36000.0: return -1.0e300
        let radians = second * 0.0174532925199432957692
        return first * (cos(radians) if component == 2.0 else sin(radians))
    return -1.0e300
