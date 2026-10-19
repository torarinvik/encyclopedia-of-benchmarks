@export("affine_converter")
fn affine_converter(slope: Float64, x: Float64, intercept: Float64) abi("C") -> Float64:
    return slope * x + intercept
