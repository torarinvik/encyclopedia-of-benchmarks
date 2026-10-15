export fn is_srilankan_phone_number(phone: ?[*]const i64, length: usize) i64 {
    if (phone == null or length == 0 or length > 15) return -1;
    const bytes = phone.?;
    for (0..length) |i| {
        if (bytes[i] < 0 or bytes[i] > 127) return -1;
    }

    const prefix_length: usize = if (bytes[0] == 48) blk: {
        if (length >= 4 and bytes[1] == 48 and bytes[2] == 57 and bytes[3] == 52) break :blk 4;
        break :blk 1;
    } else if (length >= 2 and bytes[0] == 57 and bytes[1] == 52) 2 else if (length >= 3 and bytes[0] == 43 and bytes[1] == 57 and bytes[2] == 52) 3 else return 0;

    var cursor = prefix_length;
    if (cursor + 2 > length or bytes[cursor] != 55) return 0;
    cursor += 1;
    const provider = bytes[cursor];
    cursor += 1;
    if (provider != 48 and provider != 49 and provider != 50 and provider != 52 and
        provider != 53 and provider != 54 and provider != 55 and provider != 56) return 0;

    var end = length;
    if (bytes[end - 1] == 10) end -= 1;
    const remaining = end - cursor;
    if (remaining == 8 and (bytes[cursor] == 45 or bytes[cursor] == 32)) {
        cursor += 1;
    } else if (remaining != 7) {
        return 0;
    }
    for (0..7) |i| {
        if (bytes[cursor + i] < 48 or bytes[cursor + i] > 57) return 0;
    }
    return 1;
}
