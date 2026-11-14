module hyperloglog_corrected_estimate

import math

@[export: 'hyperloglog_corrected_estimate']
pub fn hyperloglog_corrected_estimate(input &i64, length usize, mut output &u8, capacity usize) i64 {
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
        mut zeros := 0
        for rank in registers {
            sum += u64(1) << (29-rank)
            if rank == 0 { zeros++ }
        }
        mut estimate := 673.0*256.0*536870912.0/(1000.0*f64(sum))
        universe := 4294967296.0
        if estimate <= 40.0 && zeros != 0 {
            estimate = 16.0*math.log(16.0/f64(zeros))
        } else if estimate > universe/30.0 {
            if estimate >= universe { return -3 }
            estimate = -universe*math.log(1.0-estimate/universe)
        }
        if output == nil || capacity < 8 { return -2 }
        bits := math.f64_bits(estimate)
        mut staged := [8]u8{}
        for b in 0 .. 8 { staged[b] = u8((bits >> (8*b)) & 255) }
        for b in 0 .. 8 { output[b] = staged[b] }
        return 8
    }
}
