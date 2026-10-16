package monotonic_array

@(export)
is_monotonic :: proc "c" (values: [^]i64, length: u64) -> i64 {
    if length > 256 || (values == nil && length != 0) do return -1

    for i := u64(1); i < length; i += 1 {
        if values[i - 1] > values[i] {
            for j := u64(1); j < length; j += 1 {
                if values[j - 1] < values[j] do return 0
            }
            return 1
        }
    }
    return 1
}
