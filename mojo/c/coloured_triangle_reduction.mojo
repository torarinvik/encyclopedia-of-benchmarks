from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


fn triangle_binomial_mod_three(n: Int64, k: Int64) -> Int64:
    var coefficient: Int64 = 1
    var remaining_n = n
    var remaining_k = k
    while remaining_n > 0 or remaining_k > 0:
        let n_digit = remaining_n % 3
        let k_digit = remaining_k % 3
        if k_digit > n_digit: return 0
        if n_digit == 2 and k_digit == 1: coefficient = (2 * coefficient) % 3
        remaining_n //= 3
        remaining_k //= 3
    return coefficient


@export("coloured_triangle_reduction")
fn coloured_triangle_reduction(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258:
        return -1
    let n = input[0]
    if n < 1 or n > 256 or length != c_size_t(n + 1): return -1
    for index in range(Int(n)):
        let color = input[index + 1]
        if color < 0 or color > 2: return -1

    let rounds = n - 1
    var total: Int64 = 0
    for index in range(Int(n)):
        total = (total + triangle_binomial_mod_three(rounds, Int64(index))
                 * input[index + 1]) % 3
    return total if rounds % 2 == 0 else (3 - total) % 3
