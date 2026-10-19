from std.collections import InlineArray

fn fast_fact_exponent(prime: Int64, n: Int64) -> Int64:
    var exponent: Int64 = 0
    var quotient = n / prime
    while quotient > 0:
        exponent += quotient
        quotient /= prime
    return exponent

fn fast_fact_power(base_input: Int64, exp_input: UInt32) -> Int64:
    var base = base_input
    var exponent = exp_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result *= base
        exponent >>= 1
        if exponent > 0: base *= base
    return result

@export("fast_factorial")
fn fast_factorial(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 20: return -1
    if n < 2: return 1
    var prime = InlineArray[Bool, 21](False)
    for i in range(2, n + 1): prime[i] = True
    var p: Int64 = 2
    while p * p <= n:
        if prime[p]:
            var multiple = p * p
            while multiple <= n:
                prime[multiple] = False
                multiple += p
        p += 1
    let exp_two = fast_fact_exponent(2, n)
    var next_power: Int64 = 1
    var log2: UInt32 = 0
    while next_power < exp_two:
        next_power <<= 1
        log2 += 1
    let bucket_count = log2 + 1
    var buckets = InlineArray[Int64, 8](1)
    for pp in range(2, n + 1):
        if not prime[pp]: continue
        let bits = UInt32(fast_fact_exponent(pp, n))
        for bit in range(bucket_count):
            if (bits & (UInt32(1) << bit)) != 0: buckets[bit] *= pp
    var result: Int64 = 1
    for bit in range(bucket_count): result *= fast_fact_power(buckets[bit], UInt32(1) << bit)
    return result
