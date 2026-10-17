const MAX_ROWS: usize = 32;
const MAX_COLUMNS: usize = 32;
const MAX_ROWS_I64: i64 = 32;
const MAX_COLUMNS_I64: i64 = 32;
const MAX_INPUT_LENGTH: usize = 2 + MAX_ROWS * MAX_COLUMNS + 1;
const MAX_AMOUNT: i64 = 1_000_000;

export fn richest_customer_wealth(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > MAX_ROWS_I64 or values[1] < 1 or values[1] > MAX_COLUMNS_I64) return -1;
    const rows: usize = @intCast(values[0]);
    const columns: usize = @intCast(values[1]);
    if (length != 2 + rows * columns) return -1;
    var richest: i64 = 0;
    for (0..rows) |row| {
        var wealth: i64 = 0;
        for (0..columns) |column| {
            const amount = values[2 + row * columns + column];
            if (amount < 0 or amount > MAX_AMOUNT) return -1;
            wealth += amount;
        }
        if (wealth > richest) richest = wealth;
    }
    return richest;
}
