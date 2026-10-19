@export("count_numbers_divisible")
fn count_numbers_divisible(first: Float64, last: Float64, divisor: Float64) abi("C") -> Float64:
    let a = Int64(first)
    let b = Int64(last)
    let m = Int64(divisor)
    return Float64(b / m - (a - 1) / m)
