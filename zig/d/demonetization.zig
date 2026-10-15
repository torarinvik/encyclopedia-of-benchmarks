/// Count denomination combinations with the source's recursive recurrence.
const MAX_AMOUNT: i64 = 30;
const MAX_DENOMINATIONS: i64 = 4;

fn ways(amount: i64, input: [*c]const i64, count: i64) i64 {
    if (amount < 0 or count < 0) return 0;
    if (amount == 0) return 1;
    if (count == 0) return 0;
    const denomination = input[@intCast(count + 1)];
    return ways(amount, input, count - 1) + ways(amount - denomination, input, count);
}

export fn demonetization(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 6) return -1;
    const amount = input[0];
    const count = input[1];
    if (amount < -MAX_AMOUNT or amount > MAX_AMOUNT or count < 0 or count > MAX_DENOMINATIONS
        or length != @as(usize, @intCast(count + 2))) return -1;
    for (0..@as(usize, @intCast(count))) |index| {
        const denomination = input[index + 2];
        if (denomination < 1 or denomination > MAX_AMOUNT) return -1;
    }
    return ways(amount, input, count);
}
