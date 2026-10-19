@export("bitwise_addition")
fn bitwise_addition(first: UInt64, second: UInt64) abi("C") -> Int64:
    var a = first; var b = second
    while b != 0:
        let carry = a & b
        a = a ^ b
        b = carry << 1
    return Int64(a)
