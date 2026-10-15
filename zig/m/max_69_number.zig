export fn max_69_number(value: i64) i64 {
    if (value < 1 or value > 999_999_999_999_999_999) return -1;
    var place: i64 = 1;
    while (place <= @divTrunc(value, 10)) : (place *= 10) {}
    while (place > 0) : (place = @divTrunc(place, 10)) {
        const digit = @mod(@divTrunc(value, place), 10);
        if (digit == 6) return value + 3 * place;
        if (digit != 9) return -1;
    }
    return -1;
}
