from std.ffi import c_size_t
from std.math import atan2, cos, floor, isfinite, sin, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PI_VALUE = 3.14159265358979323846264338327950288
comptime TAU_VALUE = 6.28318530717958647692528676655900576
comptime MAX_N = 64

fn cmd_wrap(angle: Float64) -> Float64:
    var value = angle - floor((angle + PI_VALUE) / TAU_VALUE) * TAU_VALUE
    if value >= PI_VALUE: value -= TAU_VALUE
    if value < -PI_VALUE: value += TAU_VALUE
    return value

@export("circular_mean_direction")
fn circular_mean_direction(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 2 or length > 66:
        return -1
    let count_value = input[0]
    if not isfinite(count_value) or floor(count_value) != count_value or
        count_value < 1.0 or count_value > Float64(MAX_N):
        return -1
    let count = Int(count_value)
    if length != count + 1: return -1

    var sum_cos: Float64 = 0.0
    var sum_sin: Float64 = 0.0
    var correction_cos: Float64 = 0.0
    var correction_sin: Float64 = 0.0
    for index in range(count):
        let raw = input[index + 1]
        if not isfinite(raw) or abs(raw) > 8.0 * PI_VALUE: return -1
        let angle = cmd_wrap(raw)
        let adjusted_cos = cos(angle) - correction_cos
        let next_cos = sum_cos + adjusted_cos
        correction_cos = (next_cos - sum_cos) - adjusted_cos
        sum_cos = next_cos
        let adjusted_sin = sin(angle) - correction_sin
        let next_sin = sum_sin + adjusted_sin
        correction_sin = (next_sin - sum_sin) - adjusted_sin
        sum_sin = next_sin
    let resultant = sqrt(sum_cos * sum_cos + sum_sin * sum_sin)
    if not isfinite(resultant) or resultant <= Float64(count) * 0.0000000037252902984619140625:
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1: return -2
    output[0] = cmd_wrap(atan2(sum_sin, sum_cos))
    return 1
