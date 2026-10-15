fn append_u64(value_input: u64, output: [*]u8, capacity: usize, position: *usize) bool {
    var value = value_input;
    var digits: [20]u8 = undefined;
    var count: usize = 0;
    while (true) {
        digits[count] = '0' + @as(u8, @intCast(value % 10));
        count += 1;
        value /= 10;
        if (value == 0) break;
    }
    if (count > capacity - position.*) return false;
    while (count > 0) {
        count -= 1;
        output[position.*] = digits[count];
        position.* += 1;
    }
    return true;
}

export fn allocation_number(values: [*]const i64, length: usize,
                            output: [*]u8, output_capacity: usize) i64 {
    if (length != 2) return -1;
    if (values[0] < 1 or values[0] > 1_000_000 or values[1] < 1 or values[1] > 128 or values[1] > values[0]) return -1;
    const total: u64 = @intCast(values[0]);
    const partitions: u64 = @intCast(values[1]);
    const block = total / partitions;
    var position: usize = 0;
    var index: u64 = 0;
    while (index < partitions) : (index += 1) {
        const start = index * block + 1;
        const finish = if (index + 1 == partitions) total else (index + 1) * block;
        if (!append_u64(start, output, output_capacity, &position)) return -2;
        if (position >= output_capacity) return -2;
        output[position] = '-';
        position += 1;
        if (!append_u64(finish, output, output_capacity, &position)) return -2;
        if (index + 1 != partitions) {
            if (position >= output_capacity) return -2;
            output[position] = ',';
            position += 1;
        }
    }
    return @intCast(position);
}
