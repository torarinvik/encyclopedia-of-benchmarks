from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn integer_sqrt_i64(value: Int64, upper: Int64) -> Int64:
    var low: Int64 = 0
    var high = upper + 1
    while low + 1 < high:
        let middle = low + (high - low) // 2
        if middle * middle <= value:
            low = middle
        else:
            high = middle
    return low

@export("fermat_factorization")
fn fermat_factorization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let number = input[0]
    let max_steps = input[1]
    if number < 3 or number > 1000000000000 or number % 2 == 0 or max_steps < 0 or max_steps > 4096:
        return -1
    var candidate = integer_sqrt_i64(number, 1000000)
    if candidate * candidate < number:
        candidate += 1
    for _ in range(Int(max_steps)):
        let difference = candidate * candidate - number
        let root = integer_sqrt_i64(difference, candidate)
        if root * root == difference:
            let factor = candidate - root
            if factor > 1 and factor < number:
                return factor
        candidate += 1
    return 0
