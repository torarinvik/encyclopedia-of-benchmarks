package static_range_sum_with_upper_bound
import "core:c"

@(export)
static_range_sum_with_upper_bound :: proc "c" (input: [^]i64, length: c.size_t,
                                                output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 258 { return -1 }
    if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64 { return -1 }
    n, q := int(input[0]), int(input[1])
    if int(length) != 2+n+3*q { return -1 }
    current, scratch: [64]i64
    for i := 0; i < n; i += 1 {
        if input[2+i] < 0 || input[2+i] > 1000000000 { return -1 }
        current[i] = input[2+i]
    }
    for i := 0; i < q; i += 1 {
        b := 2+n+3*i
        if input[b] < 0 || input[b] > input[b+1] || input[b+1] > i64(n) || input[b+2] < 0 || input[b+2] > 1000000000 { return -1 }
    }
    if output == nil || capacity < c.size_t(16*q) { return -2 }
    counts: [30][65]int
    sums: [30][65]i64
    offsets: [30]int
    for level := 0; level < 30; level += 1 {
        mask := i64(1) << u64(29-level)
        for i := 0; i < n; i += 1 {
            counts[level][i+1] = counts[level][i]
            sums[level][i+1] = sums[level][i]
            if current[i] & mask == 0 { counts[level][i+1] += 1; sums[level][i+1] += current[i] }
        }
        offsets[level] = counts[level][n]
        z, o := 0, offsets[level]
        for i := 0; i < n; i += 1 {
            if current[i] & mask == 0 { scratch[z] = current[i]; z += 1 }
            else { scratch[o] = current[i]; o += 1 }
        }
        for i := 0; i < n; i += 1 { current[i] = scratch[i] }
    }
    for i := 0; i < q; i += 1 {
        b := 2+n+3*i
        l, r := int(input[b]), int(input[b+1])
        key := input[b+2]+1
        count, sum: i64
        for level := 0; level < 30; level += 1 {
            zl, zr := counts[level][l], counts[level][r]
            if key & (i64(1) << u64(29-level)) != 0 {
                count += i64(zr-zl); sum += sums[level][r]-sums[level][l]
                l += offsets[level]-zl; r += offsets[level]-zr
            } else { l = zl; r = zr }
        }
        for byte := 0; byte < 8; byte += 1 {
            output[16*i+byte] = u8((count >> u64(8*byte)) & 255)
            output[16*i+8+byte] = u8((sum >> u64(8*byte)) & 255)
        }
    }
    return i64(16*q)
}
