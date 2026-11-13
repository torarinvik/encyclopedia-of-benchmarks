from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_NUMBER = 10000
comptime MAX_BOUND = 32
comptime PRIME_COUNT = 11
comptime STAGE1_PRIMES = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31)

struct XPoint:
    var x: Int64
    var z: Int64

fn mod_norm(value_input: Int64, modulus: Int64) -> Int64:
    var value = value_input % modulus
    if value < 0: value += modulus
    return value

fn gcd_i64(left_input: Int64, right_input: Int64) -> Int64:
    var left = left_input
    var right = right_input
    if left < 0: left = -left
    if right < 0: right = -right
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn square_free(number: Int64) -> Bool:
    for divisor in range(2, Int(number) + 1):
        let d = Int64(divisor)
        if d * d > number: break
        if number % (d * d) == 0: return False
    return True

fn x_double(point: XPoint, a24: Int64, modulus: Int64) -> XPoint:
    let plus = mod_norm(point.x + point.z, modulus)
    let minus = mod_norm(point.x - point.z, modulus)
    let plus_sq = plus * plus % modulus
    let minus_sq = minus * minus % modulus
    let delta = mod_norm(plus_sq - minus_sq, modulus)
    return XPoint(
        plus_sq * minus_sq % modulus,
        delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus,
    )

fn x_add(left: XPoint, right: XPoint, difference: XPoint, modulus: Int64) -> XPoint:
    let first = mod_norm(left.x - left.z, modulus) * mod_norm(right.x + right.z, modulus) % modulus
    let second = mod_norm(left.x + left.z, modulus) * mod_norm(right.x - right.z, modulus) % modulus
    let sum_term = mod_norm(first + second, modulus)
    let difference_term = mod_norm(first - second, modulus)
    return XPoint(
        difference.z * sum_term % modulus * sum_term % modulus,
        difference.x * difference_term % modulus * difference_term % modulus,
    )

fn x_multiply(point: XPoint, scalar: Int64, a24: Int64, modulus: Int64) -> XPoint:
    var r0 = XPoint(1, 0)
    var r1 = point
    var copy = scalar
    var highest = 0
    while copy > 1:
        copy >>= 1
        highest += 1
    for bit in range(highest, -1, -1):
        if (scalar & (Int64(1) << bit)) != 0:
            r0 = x_add(r0, r1, point, modulus)
            r1 = x_double(r1, a24, modulus)
        else:
            r1 = x_add(r0, r1, point, modulus)
            r0 = x_double(r0, a24, modulus)
    return r0

@export("elliptic_curve_method_stage1")
fn elliptic_curve_method_stage1(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5: return -1
    let number = input[0]
    let curve_a = input[1]
    let point_x = input[2]
    let point_y = input[3]
    let bound = input[4]
    if number < 3 or number > MAX_NUMBER or (number & 1) == 0 or bound < 2 or bound > MAX_BOUND:
        return -1
    if curve_a < 0 or curve_a >= number or point_x < 0 or point_x >= number or point_y < 0 or point_y >= number:
        return -1
    if not square_free(number) or gcd_i64(curve_a * curve_a - 4, number) != 1: return -1
    let x_sq = point_x * point_x % number
    let rhs = (x_sq * point_x + curve_a * x_sq + point_x) % number
    if point_y * point_y % number != rhs: return -1
    let inverse_four = (number + 1) // 4 if number % 4 == 3 else (3 * number + 1) // 4
    let a24 = (curve_a + 2) * inverse_four % number
    var point = XPoint(point_x, 1)
    for index in range(PRIME_COUNT):
        let prime = Int64(STAGE1_PRIMES[index])
        if prime > bound: break
        var prime_power = prime
        while prime_power <= bound // prime: prime_power *= prime
        point = x_multiply(point, prime_power, a24, number)
        let divisor = gcd_i64(point.z, number)
        if divisor > 1:
            if divisor < number: return 1
            return 0
    return 0
