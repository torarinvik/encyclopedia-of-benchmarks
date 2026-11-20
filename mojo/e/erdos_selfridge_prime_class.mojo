from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias ES_MAX_PRIME = 100_000

fn es_is_prime(value: Int64) -> Bool:
    if value < 2: return False
    if value % 2 == 0: return value == 2
    var divisor: Int64 = 3
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 2
    return True

fn es_class_for_prime(prime: Int64, direction: Int64) -> Int64:
    var remainder = prime + direction
    var best: Int64 = 1
    var divisor: Int64 = 2
    while divisor <= remainder // divisor:
        if remainder % divisor == 0:
            if divisor > 3:
                let candidate = 1 + es_class_for_prime(divisor, direction)
                if candidate > best: best = candidate
            while remainder % divisor == 0:
                remainder //= divisor
        divisor += 1
    if remainder > 3:
        let candidate = 1 + es_class_for_prime(remainder, direction)
        if candidate > best: best = candidate
    return best

@export("erdos_selfridge_prime_class")
fn erdos_selfridge_prime_class(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 3: return -1
    if length != 2: return -1
    let prime = input[0]
    let direction = input[1]
    if prime < 2 or prime > ES_MAX_PRIME or (direction != -1 and direction != 1): return -1
    if not es_is_prime(prime): return -1
    return es_class_for_prime(prime, direction)

