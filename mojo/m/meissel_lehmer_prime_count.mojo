const MAX_INPUT: Int64 = 100_000_000
const SIEVE_LIMIT: Int = 10_000
const MAX_PRIMES: Int = 1_300
const PHI_CACHE_X: Int = 2_048
const PHI_CACHE_S: Int = 32
const PRIMES_OFFSET: Int = 10_001
const PRIME_COUNT_OFFSET: Int = 11_301
const PHI_CACHE_OFFSET: Int = 21_302
const CONTEXT_LENGTH: Int = 88_919

fn integer_sqrt(value: UInt64) -> UInt64:
    var low: UInt64 = 0
    var high = value + 1
    while low + 1 < high:
        let middle = low + (high - low) / 2
        if middle <= value / middle:
            low = middle
        else:
            high = middle
    return low

fn integer_cuberoot(value: UInt64) -> UInt64:
    var low: UInt64 = 0
    var high = value + 1
    while low + 1 < high:
        let middle = low + (high - low) / 2
        if middle <= value / middle / middle:
            low = middle
        else:
            high = middle
    return low

fn phi(mut context: InlineArray[Int64, CONTEXT_LENGTH], value: UInt64, prime_count: Int) -> Int64:
    if value == 0:
        return 0
    if prime_count == 0:
        return Int64(value)
    if prime_count == 1:
        return Int64(value - value / 2)
    let prime = UInt64(context[PRIMES_OFFSET + prime_count - 1])
    if value < prime:
        return 1
    if value <= UInt64(PHI_CACHE_X) and prime_count <= PHI_CACHE_S:
        let x = Int(value)
        let cache_index = PHI_CACHE_OFFSET + prime_count * (PHI_CACHE_X + 1) + x
        let cached = context[cache_index]
        if cached != 0:
            return cached
        let result = phi(mut context, value, prime_count - 1) - phi(mut context, value / prime, prime_count - 1)
        context[cache_index] = result
        return result
    return phi(mut context, value, prime_count - 1) - phi(mut context, value / prime, prime_count - 1)

fn lehmer_count(mut context: InlineArray[Int64, CONTEXT_LENGTH], value: UInt64) -> Int64:
    if value <= UInt64(SIEVE_LIMIT):
        return context[PRIME_COUNT_OFFSET + Int(value)]
    let a = Int(context[PRIME_COUNT_OFFSET + Int(integer_sqrt(integer_sqrt(value)))])
    let b = Int(context[PRIME_COUNT_OFFSET + Int(integer_sqrt(value))])
    let c = Int(context[PRIME_COUNT_OFFSET + Int(integer_cuberoot(value))])
    var result = phi(mut context, value, a) + Int64((b + a - 2) * (b - a + 1) / 2)
    for i in range(a, b):
        let quotient = value / UInt64(context[PRIMES_OFFSET + i])
        result -= lehmer_count(mut context, quotient)
        if i < c:
            let limit = Int(lehmer_count(mut context, integer_sqrt(quotient)))
            for j in range(i, limit):
                result -= lehmer_count(mut context, quotient / UInt64(context[PRIMES_OFFSET + j])) - Int64(j)
    return result

@export("meissel_lehmer_prime_count")
fn meissel_lehmer_prime_count(value: Int64) abi("C") -> Int64:
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
    var prime_count = 0
    for candidate in range(2, SIEVE_LIMIT + 1):
        if context[candidate] == 0:
            context[PRIMES_OFFSET + prime_count] = candidate
            prime_count += 1
        let prefix_index = PRIME_COUNT_OFFSET + candidate
        var prime_flag: Int64 = 0
        if context[candidate] == 0:
            prime_flag = 1
        context[prefix_index] = context[prefix_index - 1] + prime_flag
    return lehmer_count(mut context, UInt64(value))
