fn count_set_bits_highest_position(value: Int64) -> Int64:
    var position: Int64 = 0
    var power: Int64 = 1
    while power <= value / 2:
        power *= 2
        position += 1
    return position

fn count_set_bits_recursive(value: Int64) -> Int64:
    if value == 0: return 0
    let position = count_set_bits_highest_position(value)
    let power = Int64(1) << position
    let bits = 0 if position == 0 else position * (power >> 1)
    let remaining = value - power + 1
    return bits + remaining + count_set_bits_recursive(value - power)

@export("count_set_bits")
fn count_set_bits(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 67108863: return -1
    return count_set_bits_recursive(value)
