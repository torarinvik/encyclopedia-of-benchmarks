module exponential_histogram_window

@[export: 'exponential_histogram_window']
pub fn exponential_histogram_window(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 130 { return -1 }
    wv := unsafe { input[0] }
    nv := unsafe { input[1] }
    if wv < 1 || wv > 64 || nv < 0 || nv > 128 { return -1 }
    window := int(wv)
    n := int(nv)
    if length != usize(2+n) { return -1 }
    for i in 0 .. n {
        bit := unsafe { input[2+i] }
        if bit != 0 && bit != 1 { return -1 }
    }
    if unsafe { output == nil } || capacity < usize(8*n) { return -2 }
    mut ends := [128]int{}
    mut sizes := [128]int{}
    mut used := 0
    for time in 0 .. n {
        for used != 0 && time >= window && ends[0] <= time-window {
            for j in 1 .. used { ends[j-1] = ends[j]; sizes[j-1] = sizes[j] }
            used--
        }
        bit := unsafe { input[2+time] }
        if bit == 1 { ends[used] = time; sizes[used] = 1; used++ }
        mut size := 1
        for size <= 128 {
            mut first := used
            mut second := used
            mut found := 0
            for j in 0 .. used {
                if sizes[j] == size {
                    if found == 0 { first = j } else if found == 1 { second = j }
                    found++
                }
            }
            if found > 2 {
                sizes[second] = 2*size
                for j in first+1 .. used { ends[j-1] = ends[j]; sizes[j-1] = sizes[j] }
                used--
            }
            size *= 2
        }
        mut total := 0
        for j in 0 .. used { total += sizes[j] }
        mut oldest := 0
        if used != 0 { oldest = sizes[0] }
        mut bits := u64(2*total-oldest)
        for j in 0 .. 8 {
            unsafe { output[8*time+j] = u8(bits & 255) }
            bits >>= 8
        }
    }
    return i64(8*n)
}
