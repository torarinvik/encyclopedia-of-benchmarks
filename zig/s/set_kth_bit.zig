const INVALID_RESULT: i64 = -1;

pub export fn set_kth_bit(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return INVALID_RESULT;
    const number = input[0];
    const bit = input[1];
    if (number < 0 or number > 2_147_483_647 or bit < 0 or bit > 30) return INVALID_RESULT;
    return number | (@as(i64, 1) << @intCast(bit));
}
