package exponential_histogram_window

import "core:c"

@(export)
exponential_histogram_window :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 || input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 128 { return -1 }
    window, n := int(input[0]), int(input[1])
    if int(length) != 2+n { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] != 0 && input[2+i] != 1 { return -1 } }
    if output == nil || capacity < c.size_t(8*n) { return -2 }
    ends, sizes: [128]int
    used := 0
    for time := 0; time < n; time += 1 {
        for used != 0 && time >= window && ends[0] <= time-window {
            for j := 1; j < used; j += 1 { ends[j-1] = ends[j]; sizes[j-1] = sizes[j] }
            used -= 1
        }
        if input[2+time] == 1 { ends[used] = time; sizes[used] = 1; used += 1 }
        for size := 1; size <= 128; size *= 2 {
            first, second, found := used, used, 0
            for j := 0; j < used; j += 1 {
                if sizes[j] == size {
                    if found == 0 { first = j } else if found == 1 { second = j }
                    found += 1
                }
            }
            if found > 2 {
                sizes[second] = 2*size
                for j := first+1; j < used; j += 1 { ends[j-1] = ends[j]; sizes[j-1] = sizes[j] }
                used -= 1
            }
        }
        total := 0
        for j := 0; j < used; j += 1 { total += sizes[j] }
        oldest := 0
        if used != 0 { oldest = sizes[0] }
        bits := u64(2*total-oldest)
        for j := 0; j < 8; j += 1 { output[8*time+j] = u8(bits & 255); bits >>= 8 }
    }
    return i64(8*n)
}
