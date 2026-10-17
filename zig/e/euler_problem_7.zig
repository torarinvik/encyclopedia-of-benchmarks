const SIEVE_LIMIT: usize = 1_000_000;
const MAX_ORDINAL: i64 = 10_001;
const MAX_VALID_INPUT_LENGTH: usize = 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2;

export fn euler_problem_7(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < MAX_VALID_INPUT_LENGTH or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (length != MAX_VALID_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const ordinal = input[0];
    if (ordinal < 1 or ordinal > MAX_ORDINAL) return -1;

    var composite: [SIEVE_LIMIT]bool = @splat(false);
    var count: i64 = 0;
    for (2..SIEVE_LIMIT) |candidate| {
        if (!composite[candidate]) {
            count += 1;
            if (count == ordinal) return @intCast(candidate);
            var multiple = candidate * 2;
            while (multiple < SIEVE_LIMIT) : (multiple += candidate) composite[multiple] = true;
        }
    }
    return -1;
}
