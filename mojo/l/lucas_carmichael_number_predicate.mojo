from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VALUE = 1_000_000
comptime MAX_PARSEABLE_LENGTH = 2

@export("lucas_carmichael_number_predicate")
fn lucas_carmichael_number_predicate(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let value = input[0]
    if value < 1 or value > Int64(MAX_VALUE): return -1

    var remaining = value
    var divisor: Int64 = 2
    var composite = False
    while divisor <= remaining // divisor:
        if remaining % divisor == 0:
            composite = True
            var exponent = 0
            while remaining % divisor == 0:
                remaining //= divisor
                exponent += 1
            if exponent != 1 or (value + 1) % (divisor + 1) != 0: return 0
        divisor += 1
    if remaining > 1:
        if not composite or (value + 1) % (remaining + 1) != 0: return 0
    if composite: return 1
    return 0
