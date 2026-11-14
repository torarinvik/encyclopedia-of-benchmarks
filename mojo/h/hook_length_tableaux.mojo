# Independent hook-length count; see package README.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("hook_length_tableaux")
fn hook_length_tableaux(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0: return -1
    if input[0] < 0 or input[0] > 65536: return -1
    let rows = Int(input[0])
    if length != c_size_t(rows + 1): return -1
    var total: Int64 = 0
    var previous: Int64 = 1000000
    for i in range(rows):
        let width = input[i + 1]
        if width < 1 or width > previous: return -1
        total += width
        if total > 1000000: return -1
        previous = width
    let prime: Int64 = 998244353
    var hooks: Int64 = 1
    var height = rows
    if rows > 0:
        for col in range(Int(input[1])):
            while height > 0 and input[height] <= Int64(col): height -= 1
            for row in range(height):
                let hook = input[row + 1] - Int64(col) + Int64(height - row - 1)
                hooks = (hooks * hook) % prime
    var factorial: Int64 = 1
    for i in range(2, Int(total) + 1): factorial = (factorial * Int64(i)) % prime
    var inverse: Int64 = 1
    var exponent = prime - 2
    while exponent > 0:
        if (exponent & 1) != 0: inverse = (inverse * hooks) % prime
        hooks = (hooks * hooks) % prime
        exponent >>= 1
    return (factorial * inverse) % prime
