/// Check an odd candidate above three.
fn isCandidatePrime(value: u32) bool {
    if (value % 3 == 0) return false;
    var divisor: u32 = 5;
    while (divisor * divisor <= value) : (divisor += 6) {
        if (value % divisor == 0 or value % (divisor + 2) == 0) return false;
    }
    return true;
}

/// Find the smallest prime strictly greater than the input.
export fn next_prime_number(value: i64) i64 {
    if (value < -4096 or value > 4096) return -1;
    if (value < 2) return 2;
    if (value == 2) return 3;
    var candidate = @as(u32, @intCast(value + 1)) | 1;
    while (!isCandidatePrime(candidate)) : (candidate += 2) {}
    return candidate;
}
