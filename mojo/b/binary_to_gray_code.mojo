@export("binary_to_gray_code")
fn binary_to_gray_code(value: Int64) abi("C") -> Int64:
    if value < 0: return -1
    return value ^ (value >> 1)
