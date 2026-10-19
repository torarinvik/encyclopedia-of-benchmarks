from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn area_sample(function_id: Int64, x: Float64) -> Float64:
    if function_id == 0:
        return 5.0
    if function_id == 1:
        return x
    return x * x

@export("area_under_curve")
fn area_under_curve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4:
        return -1
    let function_id = input[0]
    let start_milli = input[1]
    let end_milli = input[2]
    let steps = input[3]
    if function_id < 0 or function_id > 2 or start_milli < 0 or start_milli > 100000 or end_milli < 0 or end_milli > 100000 or steps < 1 or steps > 10000:
        return -1
    var low = start_milli
    var high = end_milli
    if low > high:
        low = end_milli
        high = start_milli
    let start = Float64(low) / 1000.0
    let end = Float64(high) / 1000.0
    let width = (end - start) / Float64(steps)
    var x1 = start
    var y1 = area_sample(function_id, x1)
    var area: Float64 = 0.0
    for i in range(Int(steps)):
        let x2 = x1 + width
        let y2 = area_sample(function_id, x2)
        area += (y1 + y2) * width * 0.5
        x1 = x2
        y1 = y2
    return Int64(area * 1000000.0 + 0.5)
