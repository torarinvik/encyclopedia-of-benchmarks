const MAX_INPUT: i64 = 67_108_863;

fn highest_power_position(value: i64) -> u32 {
    let mut position = 0;
    let mut power = 1_i64;
    while power <= value / 2 {
        power *= 2;
        position += 1;
    }
    position
}

fn count_set_bits_recursive(value: i64) -> i64 {
    if value == 0 {
        return 0;
    }
    let position = highest_power_position(value);
    let power = 1_i64 << position;
    let bits_at_position = if position == 0 { 0 } else { i64::from(position) * (power >> 1) };
    let remaining_numbers = value - power + 1;
    bits_at_position + remaining_numbers + count_set_bits_recursive(value - power)
}

/// Count set bits across every integer from 1 through value, inclusive.
#[no_mangle]
pub extern "C" fn count_set_bits(value: i64) -> i64 {
    if !(0..=MAX_INPUT).contains(&value) {
        return -1;
    }
    count_set_bits_recursive(value)
}
