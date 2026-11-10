/// Count alternating triples as each possible last building arrives.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn number_of_ways_to_select_buildings(values: *const i64, length: usize) -> i64 {
    if length == 0 { return 0; }
    if values.is_null() || length > MAX_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let mut different_bits = 0u64;
    let mut ways = 0u64;
    let (mut zeros, mut ones, mut zero_one, mut one_zero) = (0u32, 0u32, 0u32, 0u32);
    for &value in input {
        let byte = value as u64 ^ 48;
        different_bits |= byte;
        let is_one = byte & 1 != 0;
        ways += u64::from(if is_one { one_zero } else { zero_one });
        zero_one += if is_one { zeros } else { 0 };
        one_zero += if is_one { 0 } else { ones };
        zeros += u32::from(!is_one);
        ones += u32::from(is_one);
    }
    if different_bits > 1 { return -1; }
    ways as i64
}
