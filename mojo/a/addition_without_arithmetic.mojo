@export("addition_without_arithmetic")
fn addition_without_arithmetic(left_value: Int64, right_value: Int64) abi("C") -> Int64:
    if left_value < -2147483648 or left_value > 2147483647 or right_value < -2147483648 or right_value > 2147483647:
        return -1
    var left = UInt32(left_value)
    var right = UInt32(right_value)
    while right != 0:
        let carry = left & right
        left = left ^ right
        right = carry << 1
    var result = Int64(left)
    if left > 2147483647:
        result -= 4294967296
    if (left_value < 0) == (right_value < 0) and ((result < 0) != (left_value < 0)):
        return -1
    return result
