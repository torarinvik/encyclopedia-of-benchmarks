fn isLeapYear(year: i64) bool {
    return @mod(year, 4) == 0 and (@mod(year, 100) != 0 or @mod(year, 400) == 0);
}

const CivilOrdinal = struct { year: i64, ordinal: i64 };

fn decodeOffset(offset: i64) CivilOrdinal {
    const shifted = offset + 719468;
    const era = @divFloor(shifted, 146097);
    const day_of_era = shifted - era * 146097;
    const year_of_era = @divFloor(day_of_era - @divFloor(day_of_era, 1460)
        + @divFloor(day_of_era, 36524) - @divFloor(day_of_era, 146096), 365);
    var year = year_of_era + era * 400;
    const day_of_year_march = day_of_era - (365 * year_of_era
        + @divFloor(year_of_era, 4) - @divFloor(year_of_era, 100));
    const month_march = @divFloor(5 * day_of_year_march + 2, 153);
    const day = day_of_year_march - @divFloor(153 * month_march + 2, 5) + 1;
    const month = month_march + (if (month_march < 10) @as(i64, 3) else -9);
    if (month <= 2) year += 1;
    const days_before_month = [_]i64{ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };
    const leap_adjustment: i64 = if (month > 2 and isLeapYear(year)) 1 else 0;
    return .{ .year = year, .ordinal = days_before_month[@intCast(month - 1)] + leap_adjustment + day };
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gregorian_daycount_to_ordinal_date(raw: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length < 1 or length > 2 or length != 1) return -1;
    const offset = input[0];
    if (offset < -146097 or offset > 146097) return -1;
    const destination = output orelse return -2;
    if (capacity < 16) return -2;
    const result = decodeOffset(offset);
    storeI64Le(destination, 0, result.year);
    storeI64Le(destination, 8, result.ordinal);
    return 16;
}
