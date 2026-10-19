@export("central_polygonal_numbers_sequence")
fn central_polygonal_numbers_sequence(input: Int64) abi("C") -> Int64:
    if input < 0 or input > 4294967295: return -1
    let left = input // 2 if input % 2 == 0 else input
    let right = input + 1 if input % 2 == 0 else (input + 1) // 2
    return left * right + 1
