module unique_occurrences

// Check whether every present value has a distinct occurrence count.
@[export: 'unique_occurrences']
pub fn unique_occurrences(values &i64, length usize) i64 {
    if length == 0 { return 1 }
    if length > 1000 { return -1 }
    first := u64(unsafe { values[0] })
    if length == 1 { return if first + 1000 <= 2000 { i64(1) } else { i64(-1) } }
    mut largest_biased := u64(0)
    mut different_bits := u64(0)
    for index in 0 .. length {
        value := u64(unsafe { values[index] })
        different_bits |= value ^ first
        biased := value + 1000
        if biased > largest_biased { largest_biased = biased }
    }
    if largest_biased > 2000 { return -1 }
    if different_bits == 0 { return 1 }

    mut counts := [2001]u16{}
    mut touched := [44]u16{}
    mut distinct := 0
    for index in 0 .. length {
        slot := int(unsafe { values[index] } + 1000)
        if counts[slot] == 0 {
            next_distinct := distinct + 1
            if next_distinct * (next_distinct + 1) > 2 * int(length) { return 0 }
            touched[distinct] = u16(slot)
            distinct = next_distinct
        }
        counts[slot]++
    }
    mut seen := [16]u64{}
    for index in 0 .. distinct {
        frequency := int(counts[touched[index]])
        word := frequency >> 6
        bit := u64(1) << (frequency & 63)
        if (seen[word] & bit) != 0 { return 0 }
        seen[word] |= bit
    }
    return 1
}
