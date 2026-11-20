from std.ffi import c_size_t
from std.math import cos, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_PARSEABLE_INPUT_LENGTH = 19
comptime PI_PINNED = 3.14159265358979323846264338327950288

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

fn compute(n: Int, input: UnsafePointer[Float64, ImmutAnyOrigin]) -> Float64:
    var result = 0.0
    for k in range(0, n + 1):
        var inner = 0.0
        for j in range(1, n // 2 + 1):
            let bj = 1.0 if j == n // 2 else 2.0
            let denominator = Float64(4 * j * j - 1)
            let angle = (((2.0 * Float64(j)) * Float64(k)) * PI_PINNED) / Float64(n)
            let term = (bj / denominator) * cos(angle)
            inner += term
        let gk = 1.0 if k == 0 or k == n else 2.0
        let weight = (gk / Float64(n)) * (1.0 - inner)
        result += weight * input[k + 1]
    return result

@export("clenshaw_curtis_quadrature")
fn clenshaw_curtis_quadrature(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 4 or input_length > MAX_PARSEABLE_INPUT_LENGTH: return -1
    if not exact_integer(input[0], 2, 16): return -1
    let n = Int(input[0])
    if n % 2 != 0 or input_length != n + 2: return -1
    for i in range(1, Int(input_length)):
        if not isfinite(input[i]) or input[i] > 1000.0 or input[i] < -1000.0: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    let result = compute(n, input)
    if not isfinite(result): return -1
    output[0] = result
    return 1
