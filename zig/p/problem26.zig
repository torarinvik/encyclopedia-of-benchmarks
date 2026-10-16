export fn problem26(limit: i64) i64 {
    if (limit < 0 or limit > 1000) return -1;
    var best_denominator: i64 = 1;
    var longest_remainder_list: i64 = 0;
    var denominator: i64 = 1;
    while (denominator <= limit) : (denominator += 1) {
        var seen = [_]bool{false} ** 1001;
        var remainder: i64 = 1;
        var remainder_count: i64 = 0;
        var step: i64 = 0;
        while (step < limit) : (step += 1) {
            if (seen[@intCast(remainder)]) {
                if (remainder_count > longest_remainder_list) {
                    longest_remainder_list = remainder_count;
                    best_denominator = denominator;
                }
                break;
            }
            seen[@intCast(remainder)] = true;
            remainder_count += 1;
            remainder = @rem(remainder * 10, denominator);
        }
    }
    return best_denominator;
}
