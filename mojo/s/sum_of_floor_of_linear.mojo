from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn floor_sum(n_in: Int64, m_in: Int64, a_in: Int64, b_in: Int64) -> Int64:
    var n = n_in
    var m = m_in
    var a = a_in
    var b = b_in
    var answer: Int64 = 0
    while True:
        if a >= m:
            let quotient = a // m
            var left = n
            var right = n - 1
            if left % 2 == 0: left = left // 2
            else: right = right // 2
            answer += left * right * quotient
            a = a % m
        if b >= m:
            answer += n * (b // m)
            b = b % m
        let numerator = a * n + b
        let height = numerator // m
        if height == 0: return answer
        b = numerator % m
        n = height
        let previous_m = m
        m = a
        a = previous_m
    return answer

@export("sum_of_floor_of_linear")
fn sum_of_floor_of_linear(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    let n = input[0]
    let m = input[1]
    let a = input[2]
    let b = input[3]
    if n < 1 or n > 1000000000 or m < 1 or m > 1000000000: return -1
    if a < 0 or a >= m or b < 0 or b >= m: return -1
    return floor_sum(n, m, a, b)
