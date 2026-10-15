fn msdOrderKey(value: i64) u64 {
    const sign_bit = @as(u64, 1) << 63;
    if (value < 0) return sign_bit - 1 - @as(u64, @intCast(-(value + 1)));
    return sign_bit + @as(u64, @intCast(value));
}

fn msdSortRange(values: [*]i64, begin: usize, end: usize, bit: i32) void {
    if (end - begin < 2 or bit < 0) return;
    var left = begin;
    var right = end;
    while (left < right) {
        while (left < right and ((msdOrderKey(values[left]) >> @as(u6, @intCast(bit))) & 1) == 0) : (left += 1) {}
        while (left < right and ((msdOrderKey(values[right - 1]) >> @as(u6, @intCast(bit))) & 1) != 0) : (right -= 1) {}
        if (left < right) {
            const temporary = values[left];
            values[left] = values[right - 1];
            values[right - 1] = temporary;
            left += 1;
            right -= 1;
        }
    }
    msdSortRange(values, begin, left, bit - 1);
    msdSortRange(values, left, end, bit - 1);
}

/// In-place most-significant-bit radix sort for signed 64-bit values.
export fn msd_radix_sort(values: [*]i64, length: usize) void {
    if (length > 1) msdSortRange(values, 0, length, 63);
}
