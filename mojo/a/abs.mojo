@export("abs_i64")
fn abs_i64(input: Int64) abi("C") -> Int64:
    if input == Int64.min:
        return -1
    if input < 0:
        return -input
    return input
