package hyperloglog_corrected_estimate

import "core:c"
import "core:math"

@(export)
hyperloglog_corrected_estimate :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 130 do return -1
    raw := input[0]
    if raw < 0 || raw > 128 || length != c.size_t(raw+1) do return -1
    registers: [16]u32
    for i := 0; i < int(raw); i += 1 {
        value := input[i+1]
        if value < 0 || value > 4294967295 do return -1
        hash := u32(value)
        bucket := int(hash >> 28)
        suffix := hash & 0x0fffffff
        rank: u32 = 1
        mask: u32 = 1 << 27
        for mask != 0 && (suffix & mask) == 0 { rank += 1; mask >>= 1 }
        if rank > registers[bucket] { registers[bucket] = rank }
    }
    sum: u64 = 0
    zeros := 0
    for rank in registers {
        sum += u64(1) << (29-rank)
        if rank == 0 { zeros += 1 }
    }
    estimate := f64(673.0*256.0*536870912.0)/(1000.0*f64(sum))
    universe := f64(4294967296.0)
    if estimate <= 40.0 && zeros != 0 {
        estimate = 16.0*math.ln(16.0/f64(zeros))
    } else if estimate > universe/30.0 {
        if estimate >= universe do return -3
        estimate = -universe*math.ln(1.0-estimate/universe)
    }
    if output == nil || capacity < 8 do return -2
    bits := transmute(u64)estimate
    staged: [8]u8
    for b := 0; b < 8; b += 1 { staged[b] = u8((bits >> (8*b)) & 255) }
    for b := 0; b < 8; b += 1 { output[b] = staged[b] }
    return 8
}
