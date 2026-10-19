from std.math import pow

@export("circle")
fn circle(radius: Float64, operation: Float64) abi("C") -> Float64:
    if radius != radius or operation != operation or radius < -1000000.0 or radius > 1000000.0 or (operation != 0.0 and operation != 1.0): return -1.0e300
    let pi = 3.14159265358979323846
    if operation == 0.0: return radius * 2.0 * pi
    return pow(radius, 2.0) * pi
