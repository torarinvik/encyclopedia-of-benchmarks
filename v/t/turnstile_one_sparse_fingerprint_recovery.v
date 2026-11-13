const sparse_fingerprint_modulus = i64(1000000007)

fn sparse_fingerprint_power(base_value i64, exponent_value i64) i64 {
    mut base := base_value
    mut exponent := exponent_value
    mut result := i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 { result = result * base % sparse_fingerprint_modulus }
        base = base * base % sparse_fingerprint_modulus
        exponent >>= 1
    }
    return result
}

@[export: 'turnstile_one_sparse_fingerprint_recovery']
pub fn turnstile_one_sparse_fingerprint_recovery(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 3 || length > 260 { return -1 }
        n := input[0]
        q := input[1]
        base := input[2]
        if n < 1 || n > 64 || q < 0 || q > 128 || base < 1 || base >= sparse_fingerprint_modulus { return -1 }
        if length != usize(3 + 2 * q) { return -1 }
        mut mass := i64(0)
        mut weighted := i64(0)
        mut fingerprint := i64(0)
        for i in 0 .. int(q) {
            index := input[3 + 2 * i]
            delta := input[4 + 2 * i]
            if index < 0 || index >= n || delta < -1000 || delta > 1000 { return -1 }
            mass += delta
            weighted += delta * index
            fingerprint = (fingerprint + delta * sparse_fingerprint_power(base, index)) % sparse_fingerprint_modulus
            if fingerprint < 0 { fingerprint += sparse_fingerprint_modulus }
        }
        if mass == 0 || weighted % mass != 0 { return 0 }
        index := weighted / mass
        if index < 0 || index >= n { return 0 }
        mut expected := (mass * sparse_fingerprint_power(base, index)) % sparse_fingerprint_modulus
        if expected < 0 { expected += sparse_fingerprint_modulus }
        if fingerprint == expected { return index + 1 }
        return 0
    }
}
