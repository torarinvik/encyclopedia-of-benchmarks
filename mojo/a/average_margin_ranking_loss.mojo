from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("average_margin_ranking_loss")
fn average_margin_ranking_loss(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 515: return -1.0e300
    let count = values[0]
    let margin = values[1]
    let label = values[2]
    if count < 1 or count > 256 or length != c_size_t(2 * count + 3) or margin < 0 or margin > 1000 or (label != -1 and label != 1): return -1.0e300
    var total: Float64 = 0.0
    for i in range(Int(count)):
        let first = values[3 + i]
        let second = values[3 + Int(count) + i]
        if first < -1000 or first > 1000 or second < -1000 or second > 1000: return -1.0e300
        let loss = Float64(margin) - Float64(label) * (Float64(first) - Float64(second))
        if loss > 0.0: total += loss
    return total / Float64(count)
