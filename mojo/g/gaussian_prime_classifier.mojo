from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_COORDINATE = 10_000

fn gp_rational_prime(value: Int64) -> Bool:
    if value < 2: return False
    if value % 2 == 0: return value == 2
    var divisor: Int64 = 3
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 2
    return True

@export("gaussian_prime_classifier")
fn gaussian_prime_classifier(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 3: return -1
    if length != 2: return -1
    let real = input[0]
    let imaginary = input[1]
    if real < -MAX_COORDINATE or real > MAX_COORDINATE or
        imaginary < -MAX_COORDINATE or imaginary > MAX_COORDINATE: return -1
    if real == 0 and imaginary == 0: return 0
    if real == 0 or imaginary == 0:
        let axis = if real == 0: imaginary else: real
        let rational = if axis < 0: -axis else: axis
        if rational % 4 == 3 and gp_rational_prime(rational): return 1
        return 0
    let norm = real * real + imaginary * imaginary
    if gp_rational_prime(norm): return 1
    return 0
