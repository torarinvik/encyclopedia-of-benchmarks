@export("babylonian_method")
fn babylonian_method(input: Float64) abi("C") -> Float64:
    if not (input >= 2.0 and input <= 999999.0):
        return -1.0
    let n = Int64(input)
    if Float64(n) != input:
        return -1.0
    var i: Int64 = 1
    while i * i <= n:
        i += 1
    i -= 1
    if i * i == n:
        return -1.0
    let x0 = Float64(i)
    return (input / x0 + x0) / 2.0
