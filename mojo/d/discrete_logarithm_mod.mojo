from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime TABLE_SIZE = 65_536
comptime TABLE_MASK = TABLE_SIZE - 1
comptime MAX_MODULUS = UInt64(1_000_000_000)

fn gcd(left_value: UInt64, right_value: UInt64) -> UInt64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn ceil_sqrt(value: UInt64) -> UInt64:
    var low: UInt64 = 1
    var high: UInt64 = 31_623
    while low < high:
        let middle = low + (high - low) / 2
        if middle * middle >= value:
            high = middle
        else:
            low = middle + 1
    return low

fn pow_mod(initial_base: UInt64, initial_exponent: UInt64, modulus: UInt64) -> UInt64:
    var base = initial_base
    var exponent = initial_exponent
    var result: UInt64 = 1 % modulus
    while exponent != 0:
        if (exponent & 1) != 0:
            result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result

fn inverse_mod(value: UInt64, modulus: UInt64) -> Int64:
    var old_r = Int64(value)
    var r = Int64(modulus)
    var old_t: Int64 = 1
    var t: Int64 = 0
    while r != 0:
        let quotient = old_r / r
        let next_r = old_r - quotient * r
        let next_t = old_t - quotient * t
        old_r = r
        r = next_r
        old_t = t
        t = next_t
    if old_r != 1:
        return -1
    old_t %= Int64(modulus)
    if old_t < 0:
        old_t += Int64(modulus)
    return old_t

fn insert_baby(keys: List[UInt64], steps: List[UInt32], key: UInt64, step: UInt32):
    var slot = Int(key & UInt64(TABLE_MASK))
    while steps[slot] != 0:
        if keys[slot] == key:
            return
        slot = (slot + 1) & TABLE_MASK
    keys[slot] = key
    steps[slot] = step + 1

fn find_baby(keys: List[UInt64], steps: List[UInt32], key: UInt64) -> Int64:
    var slot = Int(key & UInt64(TABLE_MASK))
    while steps[slot] != 0:
        if keys[slot] == key:
            return Int64(steps[slot] - 1)
        slot = (slot + 1) & TABLE_MASK
    return -1

fn coprime_log(x: UInt64, y: UInt64, modulus: UInt64) -> Int64:
    if y == 1 % modulus:
        return 0
    let width = ceil_sqrt(modulus)
    var keys = List[UInt64](capacity=TABLE_SIZE)
    var steps = List[UInt32](capacity=TABLE_SIZE)
    for _ in range(TABLE_SIZE):
        keys.append(0)
        steps.append(0)
    var residue: UInt64 = 1 % modulus
    for step in range(width):
        insert_baby(keys, steps, residue, UInt32(step))
        residue = (residue * x) % modulus
    let inverse = inverse_mod(x, modulus)
    if inverse < 0:
        return -1
    let giant_factor = pow_mod(UInt64(inverse), width, modulus)
    var giant = y
    var block: UInt64 = 0
    while block * width <= modulus:
        let baby = find_baby(keys, steps, giant)
        if baby >= 0:
            let answer = block * width + UInt64(baby)
            if answer <= modulus:
                return Int64(answer)
            return -1
        giant = (giant * giant_factor) % modulus
        block += 1
    return -1

fn extended_log(x: UInt64, initial_y: UInt64, initial_modulus: UInt64) -> Int64:
    var y = initial_y
    var modulus = initial_modulus
    if modulus == 1:
        return 0
    var accumulator: UInt64 = 1
    var added: UInt64 = 0
    while gcd(x, modulus) > 1:
        let divisor = gcd(x, modulus)
        if y == accumulator:
            return Int64(added)
        if y % divisor != 0:
            return -1
        y /= divisor
        modulus /= divisor
        accumulator = (accumulator * (x / divisor)) % modulus
        added += 1
        if modulus == 1:
            return Int64(added)
    let inverse = inverse_mod(accumulator, modulus)
    if inverse < 0:
        return -1
    let target = (y * UInt64(inverse)) % modulus
    let remaining = coprime_log(x % modulus, target, modulus)
    if remaining < 0:
        return -1
    return Int64(added) + remaining

@export("discrete_logarithm_mod")
fn discrete_logarithm_mod(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let x = input[0]
    let y = input[1]
    let modulus = input[2]
    if x < 0 or y < 0 or modulus < 1 or UInt64(modulus) > MAX_MODULUS or x >= modulus or y >= modulus:
        return -1
    return extended_log(UInt64(x), UInt64(y), UInt64(modulus))
