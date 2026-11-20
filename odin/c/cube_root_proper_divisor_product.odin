package cube_root_proper_divisor_product

import "core:c"

MAX_INPUT_LENGTH :: 2
MAX_VALUE :: 600_000
MAX_K :: i64(50_000)

build_prime_prefix :: proc "contextless" (prefix: [^]u32) {
    prefix[0] = 0
    prefix[1] = 0
    for value := 2; value <= MAX_VALUE; value += 1 do prefix[value] = 1
    for prime := 2; prime <= MAX_VALUE / prime; prime += 1 {
        if prefix[prime] != 0 {
            for multiple := prime * prime; multiple <= MAX_VALUE; multiple += prime {
                prefix[multiple] = 0
            }
        }
    }
    for value := 1; value <= MAX_VALUE; value += 1 do prefix[value] += prefix[value - 1]
}

is_prime :: proc "contextless" (value: int, prefix: [^]u32) -> bool {
    return value >= 2 && prefix[value] - prefix[value - 1] == 1
}

count_tau_eight :: proc "contextless" (limit: int, prefix: [^]u32) -> i64 {
    count := i64(0)
    for prime := u64(2); ; prime += 1 {
        power := u64(1)
        for exponent := 0; exponent < 7; exponent += 1 {
            if power > u64(limit) / prime {
                power = u64(limit) + 1
                break
            }
            power *= prime
        }
        if power > u64(limit) do break
        if is_prime(int(prime), prefix) do count += 1
    }
    for prime := u64(2); ; prime += 1 {
        cube := prime * prime * prime
        if cube > u64(limit) do break
        if is_prime(int(prime), prefix) {
            q_max := int(u64(limit) / cube)
            count += i64(prefix[q_max])
            if prime <= u64(q_max) do count -= 1
        }
    }
    for prime := u64(2); prime * prime * prime < u64(limit); prime += 1 {
        if !is_prime(int(prime), prefix) do continue
        for other := prime + 1; ; other += 1 {
            if prime > u64(limit) / other do break
            product := prime * other
            last_prime := int(u64(limit) / product)
            if u64(last_prime) <= other do break
            if is_prime(int(other), prefix) do count += i64(prefix[last_prime] - prefix[int(other)])
        }
    }
    return count
}

sequence_term :: proc "contextless" (k: i64) -> i64 {
    if k == 1 do return 1
    prime_prefix: [MAX_VALUE + 1]u32
    build_prime_prefix(&prime_prefix[0])
    target := k - 1
    if count_tau_eight(MAX_VALUE, &prime_prefix[0]) < target do return -1
    low := 1
    high := MAX_VALUE
    for low < high {
        middle := low + (high - low) / 2
        if count_tau_eight(middle, &prime_prefix[0]) >= target do high = middle
        else low = middle + 1
    }
    return i64(low)
}

@(export)
cube_root_proper_divisor_product :: proc "c" (input: [^]i64,
    length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if length != 1 || input[0] < 1 || input[0] > MAX_K do return -1
    return sequence_term(input[0])
}
