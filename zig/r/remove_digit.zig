const INVALID_RESULT: i64 = -1;
const MIN_VALID_INPUT: i64 = -9_223_372_036_854_775_807;

export fn remove_digit(value: i64) i64 {
    if (value < MIN_VALID_INPUT) return INVALID_RESULT;
    const magnitude = if (value < 0) -value else value;
    if (magnitude < 10) return INVALID_RESULT;
    var top_place: i64 = 1;
    while (top_place <= @divTrunc(magnitude, 10)) : (top_place *= 10) {}
    var digit_count: i64 = 0;
    var place = top_place;
    while (place > 0) : (place = @divTrunc(place, 10)) {
        digit_count += 1;
    }
    var maximum: i64 = 0;
    var removed: i64 = 0;
    while (removed < digit_count) : (removed += 1) {
        var candidate: i64 = 0;
        var position: i64 = 0;
        place = top_place;
        while (place > 0) : (place = @divTrunc(place, 10)) {
            const digit = @mod(@divTrunc(magnitude, place), 10);
            if (position != removed) candidate = candidate * 10 + digit;
            position += 1;
        }
        if (candidate > maximum) maximum = candidate;
    }
    return maximum;
}
