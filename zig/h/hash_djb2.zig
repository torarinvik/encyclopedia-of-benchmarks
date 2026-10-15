const MAX_BYTES: usize = 3;

/// Hash packed ASCII bytes with the 64-bit DJB2 recurrence.
export fn hash_djb2(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_BYTES + 1) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, MAX_BYTES) or
        length != @as(usize, @intCast(count_value)) + 1) return -1;
    var hash: u64 = 5381;
    for (0..@as(usize, @intCast(count_value))) |index| {
        const byte = input[index + 1];
        if (byte < 1 or byte > 127) return -1;
        hash = hash * 33 + @as(u64, @intCast(byte));
    }
    return @intCast(hash);
}
