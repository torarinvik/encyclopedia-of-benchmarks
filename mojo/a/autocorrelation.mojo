from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("autocorrelation")
fn autocorrelation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 66:
        return -1.0e300
    let count = values[0]
    let lag = values[1]
    if count < 2 or count > 64 or length != c_size_t(count + 2) or lag < 0 or lag >= count:
        return -1.0e300
    var sum: Float64 = 0.0
    for i in range(Int(count)):
        if values[i + 2] < -1000 or values[i + 2] > 1000:
            return -1.0e300
        sum += Float64(values[i + 2])
    let mean = sum / Float64(count)
    var variance_sum: Float64 = 0.0
    for i in range(Int(count)):
        let diff = Float64(values[i + 2]) - mean
        variance_sum += diff * diff
    if variance_sum == 0.0:
        return -1.0e300
    let variance = variance_sum / Float64(count)
    var covariance_sum: Float64 = 0.0
    for i in range(Int(lag), Int(count)):
        let current = Float64(values[i + 2]) - mean
        let delayed = Float64(values[i - Int(lag) + 2]) - mean
        covariance_sum += current * delayed
    return (covariance_sum / Float64(count)) / variance
