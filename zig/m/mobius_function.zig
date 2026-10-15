/// Return the Möbius function for a bounded positive integer.
export fn mobius_function(n: i64) i64 {
    if (n < 1 or n > 10_000) return std.math.minInt(i64);
    var remaining = n;
    var distinct_factor_count: i64 = 0;
    var factor: i64 = 2;
    while (factor * factor <= remaining) : (factor += 1) {
        if (@rem(remaining, factor) == 0) {
            remaining = @divTrunc(remaining, factor);
            if (@rem(remaining, factor) == 0) return 0;
            distinct_factor_count += 1;
        }
    }
    if (remaining > 1) distinct_factor_count += 1;
    return if (@rem(distinct_factor_count, 2) == 0) 1 else -1;
}

const std = @import("std");
