const MAX_N: usize = 64;
const MAX_VALUE: i64 = 255;
const ABSENT_CODE: i64 = 64;
const PACK_BASE: i64 = 65;

export fn bond_sequential_search(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_N + 4) return -1;
    const values = input.?;
    const count_value = values[0];
    const key_a = values[1];
    const key_b = values[2];
    if (count_value < 0 or count_value > MAX_N or length != @as(usize, @intCast(count_value)) + 3
        or key_a < 0 or key_a > MAX_VALUE or key_b < 0 or key_b > MAX_VALUE or key_a == key_b) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |i| {
        const value = values[i + 3];
        if (value < 0 or value > MAX_VALUE) return -1;
    }

    var index_a: i64 = ABSENT_CODE;
    var index_b: i64 = ABSENT_CODE;
    const composite = key_a | key_b;
    for (0..count) |i| {
        if (index_a != ABSENT_CODE and index_b != ABSENT_CODE) break;
        const value = values[i + 3];
        if (value & composite != value) continue;
        if (index_a == ABSENT_CODE and value == key_a) index_a = @intCast(i);
        if (index_b == ABSENT_CODE and value == key_b) index_b = @intCast(i);
    }
    return index_a * PACK_BASE + index_b;
}
