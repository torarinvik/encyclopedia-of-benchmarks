const MAX_MODULUS: i64 = 64;

export fn pisano_period(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 2) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 1 or input[0] > MAX_MODULUS) return -1;
    const modulus = input[0];
    const initial_next = @mod(@as(i64, 1), modulus);
    var previous: i64 = 0;
    var current = initial_next;
    var period: i64 = 1;
    while (period <= 6 * modulus) : (period += 1) {
        const next = @mod(previous + current, modulus);
        previous = current;
        current = next;
        if (previous == 0 and current == initial_next) return period;
    }
    return -1;
}
