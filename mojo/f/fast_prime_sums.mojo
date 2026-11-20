from std.collections import InlineArray

const MAX_INPUT: Int64 = 1_000_000_000
const SIEVE_LIMIT: Int = 32_000
const PRIME_CAPACITY: Int = 3_500
const PHI_ROWS: Int = 12
const PHI_COLUMNS: Int = 30_000
const PRIMES_OFFSET: Int = 32_001
const PRIME_COUNT_OFFSET: Int = 35_501
const PRIME_SUM_OFFSET: Int = 67_502
const PHI_OFFSET: Int = 99_503
const CONTEXT_LENGTH: Int = 459_503

fn integer_sqrt(value: Int64) -> Int64:
    var low: Int64 = 0
    var high = value + 1
    while low + 1 < high:
        let middle = low + (high - low) / 2
        if middle <= value / middle:
            low = middle
        else:
            high = middle
    return low

fn integer_cuberoot(value: Int64) -> Int64:
    var low: Int64 = 0
    var high: Int64 = 1
    while high * high * high <= value:
        high *= 2
    while low + 1 < high:
        let middle = low + (high - low) / 2
        if middle * middle * middle <= value:
            low = middle
        else:
            high = middle
    return low

fn weighted_phi(mut context: InlineArray[Int64, CONTEXT_LENGTH], value: Int64, count: Int) -> Int64:
    if value <= 0:
        return 0
    if count == 0:
        return value * (value + 1) / 2
    let prime = context[PRIMES_OFFSET + count - 1]
    if value <= prime:
        return 1
    if count < PHI_ROWS and value < Int64(PHI_COLUMNS):
        return context[PHI_OFFSET + count * PHI_COLUMNS + Int(value)]
    if value < Int64(SIEVE_LIMIT) and prime * prime >= value:
        return context[PRIME_SUM_OFFSET + Int(value)] - context[PRIME_SUM_OFFSET + Int(prime)] + 1
    if value < Int64(SIEVE_LIMIT) and prime * prime * prime >= value:
        var result = context[PRIME_SUM_OFFSET + Int(value)] - context[PRIME_SUM_OFFSET + Int(prime)] + 1
        let limit = Int(context[PRIME_COUNT_OFFSET + Int(integer_sqrt(value))])
        for index in range(count, limit):
            let other = context[PRIMES_OFFSET + index]
            result += other * (context[PRIME_SUM_OFFSET + Int(value / other)] - context[PRIME_SUM_OFFSET + Int(other - 1)])
        return result
    return weighted_phi(mut context, value, count - 1) - prime * weighted_phi(mut context, value / prime, count - 1)

fn sum_primes(mut context: InlineArray[Int64, CONTEXT_LENGTH], value: Int64) -> Int64:
    if value <= Int64(SIEVE_LIMIT):
        return context[PRIME_SUM_OFFSET + Int(value)]
    let cube = Int(integer_cuberoot(value))
    let square = Int(integer_sqrt(value))
    let first = Int(context[PRIME_COUNT_OFFSET + cube])
    let last = Int(context[PRIME_COUNT_OFFSET + square])
    var result = weighted_phi(mut context, value, first) + context[PRIME_SUM_OFFSET + cube] - 1
    for index in range(first, last):
        let prime = context[PRIMES_OFFSET + index]
        let quotient = value / prime
        result -= (sum_primes(mut context, quotient) - context[PRIME_SUM_OFFSET + Int(prime - 1)]) * prime
    return result

@export("fast_prime_sums")
fn fast_prime_sums(value: Int64) abi("C") -> Int64:
    if value < 0 or value > MAX_INPUT:
        return -1
    var context = InlineArray[Int64, CONTEXT_LENGTH](fill=0)
    for candidate in range(2, SIEVE_LIMIT + 1):
        if context[candidate] != 0:
            continue
        if candidate <= SIEVE_LIMIT / candidate:
            var multiple = candidate * candidate
            while multiple <= SIEVE_LIMIT:
                context[multiple] = 1
                multiple += candidate
    var count = 0
    for candidate in range(2, SIEVE_LIMIT + 1):
        if context[candidate] == 0:
            context[PRIMES_OFFSET + count] = candidate
            count += 1
        var prime_increment: Int64 = 0
        if context[candidate] == 0:
            prime_increment = 1
        context[PRIME_COUNT_OFFSET + candidate] = context[PRIME_COUNT_OFFSET + candidate - 1] + prime_increment
        context[PRIME_SUM_OFFSET + candidate] = context[PRIME_SUM_OFFSET + candidate - 1]
        if context[candidate] == 0:
            context[PRIME_SUM_OFFSET + candidate] += candidate
    for n in range(PHI_COLUMNS):
        context[PHI_OFFSET + n] = Int64(n) * Int64(n + 1) / 2
    for row in range(1, PHI_ROWS):
        let prime = context[PRIMES_OFFSET + row - 1]
        let previous = (row - 1) * PHI_COLUMNS
        let current = row * PHI_COLUMNS
        for n in range(PHI_COLUMNS):
            context[PHI_OFFSET + current + n] = context[PHI_OFFSET + previous + n] - prime * context[PHI_OFFSET + previous + n / Int(prime)]
    return sum_primes(mut context, value)
