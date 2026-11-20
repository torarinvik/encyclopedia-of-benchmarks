from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_INPUT_LENGTH = 3
comptime MAX_STACK = 128
comptime MAX_DIVISOR_COUNT = 63
comptime MAX_LIMIT = 1_000_000
comptime PRIME_COUNT = 5

@export("smallest_number_with_n_divisors")
fn smallest_number_with_n_divisors(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH or length != 2:
        return -1
    let divisor_count = Int(input[0])
    let limit = Int(input[1])
    if divisor_count < 1 or divisor_count > MAX_DIVISOR_COUNT or limit < 1 or limit > MAX_LIMIT:
        return -1

    var remaining_stack = InlineArray[Int, MAX_STACK](fill=0)
    var max_factor_stack = InlineArray[Int, MAX_STACK](fill=0)
    var prime_index_stack = InlineArray[Int, MAX_STACK](fill=0)
    var product_stack = InlineArray[Int, MAX_STACK](fill=0)
    var primes = InlineArray[Int, PRIME_COUNT](fill=0)
    primes[0] = 2
    primes[1] = 3
    primes[2] = 5
    primes[3] = 7
    primes[4] = 11
    var top = 1
    remaining_stack[0] = divisor_count
    max_factor_stack[0] = divisor_count
    product_stack[0] = 1
    var best = limit + 1

    while top != 0:
        top -= 1
        let remaining = remaining_stack[top]
        let max_factor = max_factor_stack[top]
        let prime_index = prime_index_stack[top]
        let product = product_stack[top]
        if remaining == 1:
            if product < best:
                best = product
            continue
        if prime_index >= PRIME_COUNT:
            continue
        let prime = primes[prime_index]
        let factor_limit = min(max_factor, remaining)
        for factor in range(2, factor_limit + 1):
            if remaining % factor != 0:
                continue
            var candidate = product
            var valid = True
            for step in range(1, factor):
                if candidate > limit / prime:
                    valid = False
                    break
                candidate *= prime
            if valid and candidate < best:
                if top >= MAX_STACK:
                    return -1
                remaining_stack[top] = remaining / factor
                max_factor_stack[top] = factor
                prime_index_stack[top] = prime_index + 1
                product_stack[top] = candidate
                top += 1
    return Int64(best) if best <= limit else Int64(0)
