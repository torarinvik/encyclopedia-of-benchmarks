from std.collections import InlineArray

fn fermat_random_sample(inout seed: InlineArray[Int32, 56], inout next: Int32, inout next_p: Int32) -> Int32:
    next += 1
    if next >= 56: next = 1
    next_p += 1
    if next_p >= 56: next_p = 1
    var value = seed[next] - seed[next_p]
    if value == 2147483647: value -= 1
    if value < 0: value += 2147483647
    seed[next] = value
    return value

fn fermat_mod_pow(base_input: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % modulus
        base = base * base % modulus
        exponent >>= 1
    return result

@export("fermat_prime_checker")
fn fermat_prime_checker(number: Int64, times_to_check: Int64) abi("C") -> Int64:
    if number < 2 or number > 1000000 or times_to_check < 2 or times_to_check > 64: return -1
    var seed = InlineArray[Int32, 56](0)
    var mj: Int32 = 161803398
    var mk: Int32 = 1
    seed[55] = mj
    for i in range(1, 55):
        let index = (21 * i) % 55
        seed[index] = mk
        mk = mj - mk
        if mk < 0: mk += 2147483647
        mj = seed[index]
    for pass in range(4):
        for i in range(1, 56):
            seed[i] -= seed[1 + (i + 30) % 55]
            if seed[i] < 0: seed[i] += 2147483647
    var next: Int32 = 0
    var next_p: Int32 = 21
    for iteration in range(1, times_to_check):
        let sample = fermat_random_sample(seed, next, next_p)
        let base = Int64(Float64(sample) / 2147483647.0 * Float64(number - 1)) + 1
        if fermat_mod_pow(base, number - 1, number) != 1: return 0
    return 1
