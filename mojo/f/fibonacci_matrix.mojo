@export("fibonacci_matrix")
fn fibonacci_matrix(index: Int64) abi("C") -> Int64:
    if index < 0 or index > 92: return -1
    if index == 0: return 0
    var r00: Int64 = 1
    var r01: Int64 = 0
    var r10: Int64 = 0
    var r11: Int64 = 1
    var b00: Int64 = 1
    var b01: Int64 = 1
    var b10: Int64 = 1
    var b11: Int64 = 0
    var exponent = index - 1
    while exponent > 0:
        if exponent % 2 == 1:
            let n00 = r00 * b00 + r01 * b10
            let n01 = r00 * b01 + r01 * b11
            let n10 = r10 * b00 + r11 * b10
            let n11 = r10 * b01 + r11 * b11
            r00 = n00; r01 = n01; r10 = n10; r11 = n11
            exponent -= 1
        else:
            let n00 = b00 * b00 + b01 * b10
            let n01 = b00 * b01 + b01 * b11
            let n10 = b10 * b00 + b11 * b10
            let n11 = b10 * b01 + b11 * b11
            b00 = n00; b01 = n01; b10 = n10; b11 = n11
            exponent /= 2
    return r00
