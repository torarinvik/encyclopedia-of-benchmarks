from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("pell_fundamental_solution")
fn pell_fundamental_solution(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1

    let d = values[0]
    if d < 2 or d > 31:
        return -1

    var root: Int64 = 1
    while (root + 1) * (root + 1) <= d:
        root += 1
    if root * root == d:
        return -1

    var m: Int64 = 0
    var denominator: Int64 = 1
    var a = root
    var h_two_back: Int64 = 0
    var h_previous: Int64 = 1
    var q_two_back: Int64 = 1
    var q_previous: Int64 = 0

    while True:
        let x = a * h_previous + h_two_back
        let y = a * q_previous + q_two_back
        if x * x - d * y * y == 1:
            return x * 4294967296 + y

        h_two_back = h_previous
        h_previous = x
        q_two_back = q_previous
        q_previous = y

        m = denominator * a - m
        denominator = (d - m * m) // denominator
        a = (root + m) // denominator
