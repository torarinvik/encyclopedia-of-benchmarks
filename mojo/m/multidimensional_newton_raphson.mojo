from std.ffi import c_size_t
from std.math import floor
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MIN_COORDINATE = 900
alias MAX_COORDINATE = 1500
alias MAX_UPDATES = 8

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

fn round_nano(value: Float64) -> Int64:
    let magnitude = if value < 0.0: 0.0 - value else: value
    let rounded = Int64(floor(magnitude * 1_000_000_000.0 + 0.5))
    return if value < 0.0: 0 - rounded else: rounded

@export("multidimensional_newton_raphson")
fn multidimensional_newton_raphson(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4:
        return -1
    if length != 3: return -1
    let x_milli = input[0]
    let y_milli = input[1]
    let updates = input[2]
    if (x_milli < MIN_COORDINATE or x_milli > MAX_COORDINATE
            or y_milli < MIN_COORDINATE or y_milli > MAX_COORDINATE
            or updates < 1 or updates > MAX_UPDATES):
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16:
        return -2

    var x = Float64(x_milli) / 1000.0
    var y = Float64(y_milli) / 1000.0
    for _ in range(Int(updates)):
        let f1 = x * x + y - 3.0
        let f2 = x + y * y - 3.0
        let determinant = 4.0 * x * y - 1.0
        let dx = (2.0 * y * f1 - f2) / determinant
        let dy = (2.0 * x * f2 - f1) / determinant
        x -= dx
        y -= dy
    store_i64_le(output, 0, round_nano(x))
    store_i64_le(output, 8, round_nano(y))
    return 16
