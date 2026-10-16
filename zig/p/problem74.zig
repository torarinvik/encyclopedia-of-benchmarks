/// Count starts with the source's memoized digit-factorial chain length.
const MAX_START: i64 = 1_000_000;
const CACHE_SIZE: usize = 2_540_161;
const MAX_PATH_LENGTH: usize = 128;
const DIGIT_FACTORIALS = [_]i64{ 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880 };

fn sumDigitFactorials(value: i64) i64 {
    var remaining = value;
    var total: i64 = 0;
    while (remaining > 0) {
        total += DIGIT_FACTORIALS[@intCast(@mod(remaining, 10))];
        remaining = @divTrunc(remaining, 10);
    }
    if (value == 0) return 1;
    return total;
}

fn chainLength(start: i64, cache: *[CACHE_SIZE]u8) i64 {
    var path = [_]i64{0} ** MAX_PATH_LENGTH;
    var path_length: usize = 0;
    var current = start;
    var result: i64 = 0;
    while (true) {
        const encoded = cache.*[@intCast(current)];
        if (encoded != 0) {
            result = @as(i64, encoded) - 1;
            break;
        }
        const next_value = sumDigitFactorials(current);
        var repeats = false;
        for (0..path_length) |index| {
            if (path[index] == next_value) {
                repeats = true;
                break;
            }
        }
        if (repeats) {
            cache.*[@intCast(current)] = 1;
            result = 0;
            break;
        }
        path[path_length] = current;
        path_length += 1;
        current = next_value;
    }
    while (path_length > 0) {
        path_length -= 1;
        current = path[path_length];
        result += 1;
        cache.*[@intCast(current)] = @intCast(result + 1);
    }
    return @as(i64, cache.*[@intCast(start)]) - 1;
}

export fn problem74(num_terms: i64, max_start: i64) i64 {
    if (max_start > MAX_START) return -1;
    if (max_start <= 1) return 0;
    var cache: [CACHE_SIZE]u8 = @splat(0);
    cache[145] = 1;
    cache[169] = 4;
    cache[36301] = 4;
    cache[1454] = 4;
    cache[871] = 3;
    cache[45361] = 3;
    cache[872] = 3;
    var count: i64 = 0;
    var start: i64 = 1;
    while (start < max_start) : (start += 1) {
        if (chainLength(start, &cache) == num_terms) count += 1;
    }
    return count;
}
