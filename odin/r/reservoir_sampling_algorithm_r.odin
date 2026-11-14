package reservoir_sampling_algorithm_r

import "core:c"

@(export)
reservoir_sampling_algorithm_r :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > input[0] { return -1 }
    n, k := int(input[0]), int(input[1])
    if int(length) != 2+2*n-k { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] < -1000000 || input[2+i] > 1000000 { return -1 } }
    for i := k; i < n; i += 1 { if input[2+n+i-k] < 0 || input[2+n+i-k] > i64(i) { return -1 } }
    if output == nil || capacity < c.size_t(8*k) { return -2 }
    reservoir: [64]i64
    for i := 0; i < k; i += 1 { reservoir[i] = input[2+i] }
    for i := k; i < n; i += 1 {
        draw := int(input[2+n+i-k])
        if draw < k { reservoir[draw] = input[2+i] }
    }
    for i := 0; i < k; i += 1 {
        encoded := transmute(u64)reservoir[i]
        for j := 0; j < 8; j += 1 { output[8*i+j] = u8(encoded & 255); encoded >>= 8 }
    }
    return i64(8*k)
}
