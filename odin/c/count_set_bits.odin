package count_set_bits

MAX_INPUT :: i64(67108863)

highest_power_position :: proc(value: i64) -> int {
    position := 0
    power := i64(1)
    for power <= value / 2 {
        power *= 2
        position += 1
    }
    return position
}

count_set_bits_recursive :: proc(value: i64) -> i64 {
    if value == 0 do return 0
    position := highest_power_position(value)
    power := i64(1) << position
    bits_at_position := i64(0)
    if position > 0 do bits_at_position = i64(position) * (power >> 1)
    remaining_numbers := value - power + 1
    return bits_at_position + remaining_numbers + count_set_bits_recursive(value - power)
}

// Count set bits across every integer from 1 through value, inclusive.
@(export)
count_set_bits :: proc "c" (value: i64) -> i64 {
    if value < 0 || value > MAX_INPUT do return -1
    return count_set_bits_recursive(value)
}
