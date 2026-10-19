from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime TABLE_SIZE = 65536
comptime TABLE_MASK = TABLE_SIZE - 1
comptime MAX_MODULUS = 1000000007

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
    var high: UInt64 = 31624
    while low < high:
        let middle = low + (high - low) / 2
        if middle * middle >= value:
            high = middle
        else:
            low = middle + 1
    return low

fn insert_baby(keys: List[UInt64], steps: List[UInt32], key: UInt64, step: UInt32):
    var slot = Int(key & UInt64(TABLE_MASK))
    while steps[slot] != 0 and keys[slot] != key:
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

fn solve(a: UInt64, b: UInt64, modulus: UInt64) -> Int64:
    if gcd(a, modulus) != 1:
        return -1
    let m = ceil_sqrt(modulus)
    var keys = List[UInt64](capacity=TABLE_SIZE)
    var steps = List[UInt32](capacity=TABLE_SIZE)
    for _ in range(TABLE_SIZE):
        keys.append(0)
        steps.append(0)
    var step: UInt64 = 1
    for index in range(m):
        insert_baby(keys, steps, (step * b) % modulus, UInt32(index))
        step = (step * a) % modulus
    let giant_step = step
    var index = m
    while index <= modulus:
        let baby_index = find_baby(keys, steps, step)
        if baby_index >= 0:
            return Int64(index) - baby_index
        step = (step * giant_step) % modulus
        index += m
    return -1

@export("baby_step_giant_step")
fn baby_step_giant_step(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let a = input[0]
    let b = input[1]
    let modulus = input[2]
    if modulus < 1 or modulus > MAX_MODULUS or a < 0 or b < 0 or a >= modulus or b >= modulus:
        return -1
    return solve(UInt64(a), UInt64(b), UInt64(modulus))
