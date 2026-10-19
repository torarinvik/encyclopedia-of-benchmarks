from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn alpha_digit(value: Int64) -> Bool:
    return value >= 48 and value <= 57

fn alpha_valid(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, count: Int) -> Bool:
    for i in range(count):
        let value = input[start + i]
        if not alpha_digit(value) and (value < 97 or value > 122):
            return False
        if alpha_digit(value) and value == 48 and (i == 0 or not alpha_digit(input[start + i - 1])):
            if i + 1 < count and alpha_digit(input[start + i + 1]):
                return False
    return True

@export("alpha_numerical_sort")
fn alpha_numerical_sort(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 64:
        return -2
    let na = Int(input[0])
    if na + 1 >= Int(length) or input[1 + na] < 0 or input[1 + na] > 64:
        return -2
    let nb = Int(input[1 + na])
    if length != c_size_t(2 + na + nb) or not alpha_valid(input, 2, na) or not alpha_valid(input, 2 + na, nb):
        return -2
    var i = 0
    var j = 0
    while i < na and j < nb:
        let a = input[2 + i]
        let b = input[2 + na + j]
        if alpha_digit(a) and alpha_digit(b):
            var end_a = i
            var end_b = j
            while end_a < na and alpha_digit(input[2 + end_a]): end_a += 1
            while end_b < nb and alpha_digit(input[2 + na + end_b]): end_b += 1
            let da = end_a - i
            let db = end_b - j
            if da != db:
                if da < db: return -1
                return 1
            for k in range(da):
                let ca = input[2 + i + k]
                let cb = input[2 + na + j + k]
                if ca < cb: return -1
                if ca > cb: return 1
            i = end_a
            j = end_b
        else:
            if a < b: return -1
            if a > b: return 1
            i += 1
            j += 1
    if i == na and j == nb: return 0
    if i == na: return -1
    return 1
