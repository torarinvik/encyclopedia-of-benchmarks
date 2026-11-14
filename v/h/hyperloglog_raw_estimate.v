module hyperloglog_raw_estimate

fn hll_gcd(a0 u64, b0 u64) u64 {
    mut a := a0
    mut b := b0
    for b != 0 { r := a % b; a = b; b = r }
    return a
}

@[export: 'hyperloglog_raw_estimate']
pub fn hyperloglog_raw_estimate(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 1 || length > 130 { return -1 }
        raw := input[0]
        if raw < 0 || raw > 128 || length != usize(raw+1) { return -1 }
        mut registers := [16]int{}
        for i in 0 .. int(raw) {
            value := input[i+1]
            if value < 0 || value > 4294967295 { return -1 }
            hash := u64(value)
            bucket := int(hash >> 28)
            suffix := hash & u64(268435455)
            mut mask := u64(1) << 27
            mut rank := 1
            for mask != 0 && (suffix & mask) == 0 { rank++; mask >>= 1 }
            if rank > registers[bucket] { registers[bucket] = rank }
        }
        mut sum := u64(0)
        for rank in registers { sum += u64(1) << (29-rank) }
        mut numerator := u64(673)*256*(u64(1)<<29)
        mut denominator := u64(1000)*sum
        factor := hll_gcd(numerator,denominator)
        numerator /= factor
        denominator /= factor
        if output == nil || capacity < 144 { return -2 }
        mut words := [18]u64{}
        words[0] = numerator
        words[1] = denominator
        for i in 0 .. 16 { words[i+2] = u64(registers[i]) }
        mut staged := [144]u8{}
        for i in 0 .. 18 {
            for b in 0 .. 8 { staged[8*i+b] = u8((words[i] >> (8*b)) & 255) }
        }
        for i in 0 .. 144 { output[i] = staged[i] }
        return 144
    }
}
