module static_range_sum_with_upper_bound

@[export: 'static_range_sum_with_upper_bound']
fn static_range_sum_with_upper_bound(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length < 2 || length > 258 { return -1 }
        if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64 { return -1 }
        n := int(input[0]); q := int(input[1])
        if length != usize(2+n+3*q) { return -1 }
        mut current := [64]i64{}
        mut scratch := [64]i64{}
        for i in 0 .. n {
            if input[2+i] < 0 || input[2+i] > 1000000000 { return -1 }
            current[i] = input[2+i]
        }
        for i in 0 .. q {
            b := 2+n+3*i
            if input[b] < 0 || input[b] > input[b+1] || input[b+1] > n || input[b+2] < 0 || input[b+2] > 1000000000 { return -1 }
        }
        if isnil(output) || capacity < usize(16*q) { return -2 }
        mut counts := [1950]int{}
        mut sums := [1950]i64{}
        mut offsets := [30]int{}
        for level in 0 .. 30 {
            mask := i64(1) << (29-level)
            for i in 0 .. n {
                zero := current[i] & mask == 0
                counts[65*level+i+1] = counts[65*level+i] + if zero { 1 } else { 0 }
                sums[65*level+i+1] = sums[65*level+i] + if zero { current[i] } else { i64(0) }
            }
            offsets[level] = counts[65*level+n]
            mut z := 0; mut o := offsets[level]
            for i in 0 .. n {
                if current[i] & mask == 0 { scratch[z] = current[i]; z++ }
                else { scratch[o] = current[i]; o++ }
            }
            for i in 0 .. n { current[i] = scratch[i] }
        }
        for i in 0 .. q {
            b := 2+n+3*i
            mut l := int(input[b]); mut r := int(input[b+1])
            key := input[b+2]+1
            mut count := i64(0); mut sum := i64(0)
            for level in 0 .. 30 {
                zl := counts[65*level+l]; zr := counts[65*level+r]
                if key & (i64(1) << (29-level)) != 0 {
                    count += i64(zr-zl); sum += sums[65*level+r]-sums[65*level+l]
                    l += offsets[level]-zl; r += offsets[level]-zr
                } else { l = zl; r = zr }
            }
            for byte in 0 .. 8 {
                output[16*i+byte] = u8((count >> (8*byte)) & 255)
                output[16*i+8+byte] = u8((sum >> (8*byte)) & 255)
            }
        }
        return i64(16*q)
    }
}
