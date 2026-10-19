@export("binary_step")
fn binary_step(value: Float64) abi("C") -> Float64:
    if not (value >= -1_000_000.0 and value <= 1_000_000.0): return -1.0e300
    return 1.0 if value >= 0.0 else 0.0
