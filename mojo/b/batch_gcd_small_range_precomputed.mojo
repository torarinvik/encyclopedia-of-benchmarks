from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias BG_MAX_VALUE = 64
alias BG_MAX_QUERIES = 64
alias BG_MAX_INPUT_LENGTH = 2 + 2 * BG_MAX_QUERIES
alias BG_MAX_SMALL = 8

fn bg_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("batch_gcd_small_range_precomputed")
fn batch_gcd_small_range_precomputed(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > BG_MAX_INPUT_LENGTH + 1:
        return -1
    let limit_value = input[0]
    let query_value = input[1]
    if limit_value < 1 or limit_value > BG_MAX_VALUE.i64() or query_value < 0 or query_value > BG_MAX_QUERIES.i64():
        return -1
    let limit = Int(limit_value)
    let queries = Int(query_value)
    if Int(length) != 2 + 2 * queries:
        return -1
    for query in range(queries):
        let left = input[2 + 2 * query]
        let right = input[3 + 2 * query]
        if left < 0 or left > limit_value or right < 0 or right > limit_value:
            return -1

    let required = 8 * queries
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var least = InlineArray[Int, BG_MAX_VALUE + 1]()
    var primes = InlineArray[Int, BG_MAX_VALUE + 1]()
    var prime_count = 0
    for value in range(2, limit + 1):
        if least[value] == 0:
            least[value] = value
            primes[prime_count] = value
            prime_count += 1
        for index in range(prime_count):
            let prime = primes[index]
            let composite = value * prime
            if composite > limit or prime > least[value]:
                break
            least[composite] = prime

    var factors = InlineArray[Int, (BG_MAX_VALUE + 1) * 3]()
    factors[3] = 1
    factors[4] = 1
    factors[5] = 1
    for value in range(2, limit + 1):
        let prime = least[value]
        let quotient = value // prime
        var a = factors[3 * quotient] * prime
        var b = factors[3 * quotient + 1]
        var c = factors[3 * quotient + 2]
        if a > b:
            let temp = a
            a = b
            b = temp
        if b > c:
            let temp = b
            b = c
            c = temp
        if a > b:
            let temp = a
            a = b
            b = temp
        factors[3 * value] = a
        factors[3 * value + 1] = b
        factors[3 * value + 2] = c

    var small_limit = 1
    while (small_limit + 1) * (small_limit + 1) <= limit:
        small_limit += 1
    var gcd_table = InlineArray[Int, (BG_MAX_SMALL + 1) * (BG_MAX_SMALL + 1)]()
    for left in range(1, small_limit + 1):
        gcd_table[(BG_MAX_SMALL + 1) * left] = left
        for right in range(1, left):
            gcd_table[(BG_MAX_SMALL + 1) * left + right] = gcd_table[(BG_MAX_SMALL + 1) * right + (left % right)]

    for query in range(queries):
        let left = Int(input[2 + 2 * query])
        var remaining = Int(input[3 + 2 * query])
        var result = 0
        if left == 0:
            result = remaining
        else:
            result = 1
            for part in range(3):
                let factor = factors[3 * left + part]
                var common = 1
                if factor <= small_limit:
                    common = gcd_table[(BG_MAX_SMALL + 1) * factor + (remaining % factor)]
                elif remaining % factor == 0:
                    common = factor
                remaining //= common
                result *= common
        bg_store_i64_le(output, 8 * query, Int64(result))
    return Int64(required)
