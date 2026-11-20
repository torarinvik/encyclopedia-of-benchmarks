from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_NUMBER: Int64 = 1000000000000
const MAX_STEPS: Int64 = 256

fn sq_isqrt(value: Int64, upper: Int64) -> Int64:
    var low: Int64 = 0
    var high = upper + 1
    while low + 1 < high:
        let middle = low + (high - low) // 2
        if middle * middle <= value:
            low = middle
        else:
            high = middle
    return low

fn sq_gcd(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn sq_reverse(number: Int64, discriminant: Int64, a: Int64, p: Int64, q: Int64, cap: Int64) -> Int64:
    let root = sq_isqrt(q, 1414214)
    if root * root != q:
        return 0
    let quotient = (a - p) // root
    var r = quotient * root + p
    var previous_s = root
    var s = (discriminant - r * r) // root
    for _ in range(Int(cap)):
        let next_quotient = (a + r) // s
        let next_r = next_quotient * s - r
        if next_r == r:
            let factor = sq_gcd(number, r)
            if factor > 1 and factor < number:
                let other = number // factor
                return min(factor, other)
            return 0
        let next_s = previous_s + next_quotient * (r - next_r)
        previous_s = s
        s = next_s
        r = next_r
    return 0

@export("squfof_semiprime_factor")
fn squfof_semiprime_factor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let number = input[0]
    let forward_cap = input[1]
    let reverse_cap = input[2]
    if number < 3 or number > MAX_NUMBER or number % 2 == 0 or forward_cap < 0 or forward_cap > MAX_STEPS or reverse_cap < 0 or reverse_cap > MAX_STEPS:
        return -1
    let exact_root = sq_isqrt(number, 1000000)
    if exact_root * exact_root == number:
        return exact_root
    let discriminant = if number % 4 == 1: 2 * number else: number
    let a = sq_isqrt(discriminant, 1414214)
    var previous_q: Int64 = 1
    var q = discriminant - a * a
    var p = a
    var index: Int64 = 1
    for _ in range(Int(forward_cap)):
        let quotient = (a + p) // q
        let next_p = quotient * q - p
        let next_q = previous_q + quotient * (p - next_p)
        previous_q = q
        q = next_q
        p = next_p
        index += 1
        if index % 2 == 0:
            let factor = sq_reverse(number, discriminant, a, p, q, reverse_cap)
            if factor != 0:
                return factor
    return 0
