module miller_rabin_primality_checker

fn next_word(state &u64) u64 {
    unsafe { state[0] += u64(0x9e3779b97f4a7c15) }
    mut z := unsafe { state[0] }
    z = (z ^ (z >> 30)) * u64(0xbf58476d1ce4e5b9)
    z = (z ^ (z >> 27)) * u64(0x94d049bb133111eb)
    return z ^ (z >> 31)
}

fn mod_power(base_input i64, exponent_input i64, modulus i64) i64 {
    mut base := base_input
    mut exponent := exponent_input
    mut result := i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 { result = (result * base) % modulus }
        base = (base * base) % modulus
        exponent >>= 1
    }
    return result
}

fn passes_witness(n i64, a i64, d i64, powers_of_two i64) bool {
    mut x := mod_power(a, d, n)
    if x == 1 || x == n - 1 { return true }
    for mut round := i64(1); round < powers_of_two; round++ {
        x = (x * x) % n
        if x == n - 1 { return true }
    }
    return false
}

@[export: 'miller_rabin_primality_checker']
pub fn miller_rabin_primality_checker(values &i64, length usize) i64 {
    if unsafe { values == nil } || length < 3 || length > 4 { return -1 }
    n := unsafe { values[0] }; rounds := unsafe { values[1] }; seed := unsafe { values[2] }
    if length != 3 || n < 5 || n > 2147483647 || (n & 1) == 0 || rounds < 1 || rounds > 64 || seed < 0 || seed > 2147483647 { return -1 }
    mut state := u64(seed)
    span := u64(n - 4)
    threshold := (u64(0) - span) % span
    mut word := u64(0)
    for {
        word = next_word(&state)
        if word >= threshold { break }
    }
    a := 2 + i64(word % span)
    mut d := n - 1; mut powers_of_two := i64(0)
    for (d & 1) == 0 { d >>= 1; powers_of_two++ }
    for _ in 0 .. rounds { if !passes_witness(n, a, d, powers_of_two) { return 0 } }
    return 1
}
