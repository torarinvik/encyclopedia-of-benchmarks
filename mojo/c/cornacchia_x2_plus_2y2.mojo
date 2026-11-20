from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_PRIME = 1_000_000
const MAX_LENGTH = 3
const PACK_BASE: Int64 = 1024

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor <= value / divisor:
        if value % divisor == 0: return False
        if divisor == 2: divisor = 3
        else: divisor += 2
    return True

fn isqrt(value: Int64) -> Int64:
    var low: Int64 = 0
    var high: Int64 = 1001
    while low + 1 < high:
        let middle = (low + high) / 2
        if middle * middle <= value: low = middle
        else: high = middle
    return low

@export("cornacchia_x2_plus_2y2")
fn cornacchia_x2_plus_2y2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let prime = input[0]
    let root = input[1]
    if prime < 3 or prime > MAX_PRIME or (prime & 1) == 0 or root < 1 or root > prime / 2: return -1
    if not is_prime(prime) or (root * root + 2) % prime != 0: return -1

    var previous = prime
    var current = root
    let limit = isqrt(prime)
    while current > limit:
        let remainder = previous % current
        previous = current
        current = remainder
    let x = current
    let numerator = prime - x * x
    if numerator <= 0 or numerator % 2 != 0: return -1
    let y_squared = numerator / 2
    let y = isqrt(y_squared)
    if y <= 0 or y * y != y_squared or x * x + 2 * y * y != prime: return -1
    return x * PACK_BASE + y
