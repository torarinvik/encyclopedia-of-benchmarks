package sieve_of_sundaram

// Count primes through limit with Sundaram's index sieve.
@(export)
sieve_of_sundaram :: proc "c" (limit: i64) -> i64 {
    if limit < 0 || limit > 4096 do return -1
    if limit < 2 do return 0

    max_index := int((limit - 1) / 2)
    composite: [2048]bool = {}
    i := 1
    for 2 * i * (i + 1) <= max_index {
        j := i
        for {
            index := i + j + 2 * i * j
            if index > max_index do break
            composite[index] = true
            j += 1
        }
        i += 1
    }

    count := i64(1)
    for index := 1; index <= max_index; index += 1 {
        if !composite[index] do count += 1
    }
    return count
}
