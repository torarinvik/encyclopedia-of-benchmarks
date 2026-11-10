module number_of_ways_to_select_buildings

const max_length = 4096

@[export: 'number_of_ways_to_select_buildings']
pub fn number_of_ways_to_select_buildings(values &i64, length usize) i64 {
    if length > max_length { return -1 }
    mut different_bits := u64(0)
    mut ways := u64(0)
    mut zeros := u32(0)
    mut ones := u32(0)
    mut zero_one := u32(0)
    mut one_zero := u32(0)
    for index in 0 .. length {
        value := u64(unsafe { values[index] }) ^ 48
        different_bits |= value
        is_one := (value & 1) != 0
        ways += u64(if is_one { one_zero } else { zero_one })
        zero_one += if is_one { zeros } else { u32(0) }
        one_zero += if is_one { u32(0) } else { ones }
        zeros += if is_one { u32(0) } else { u32(1) }
        ones += if is_one { u32(1) } else { u32(0) }
    }
    if different_bits > 1 { return -1 }
    return i64(ways)
}
