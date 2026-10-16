module monotonic_array

@[export: 'is_monotonic']
pub fn is_monotonic(values &i64, length usize) i64 {
    if length > 256 || (isnil(values) && length > 0) {
        return -1
    }

    for i in 1 .. length {
        if values[i - 1] > values[i] {
            for j in 1 .. length {
                if values[j - 1] < values[j] {
                    return 0
                }
            }
            return 1
        }
    }
    return 1
}
