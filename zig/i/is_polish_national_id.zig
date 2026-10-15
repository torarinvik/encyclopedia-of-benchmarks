const MIN_NUMBER: i64 = 10_100_000;
const MAX_NUMBER: i64 = 99_923_199_999;
const WEIGHTS = [_]i64{ 1, 3, 7, 9 };

export fn is_polish_national_id(input: [*]const i64, length: usize) i64 {
    if (length != 11) return -1;
    var number: i64 = 0;
    for (0..11) |index| {
        const value = input[index];
        if (value < 48 or value > 57) return -1;
        number = number * 10 + value - 48;
    }
    if (number < MIN_NUMBER or number > MAX_NUMBER) return 0;
    const month = (input[2] - 48) * 10 + input[3] - 48;
    const valid_month = (month >= 1 and month <= 12) or (month >= 21 and month <= 32) or
        (month >= 41 and month <= 52) or (month >= 61 and month <= 72) or (month >= 81 and month <= 92);
    if (!valid_month) return 0;
    const day = (input[4] - 48) * 10 + input[5] - 48;
    if (day < 1 or day > 31) return 0;
    var subtotal: i64 = 0;
    for (0..10) |index| subtotal += ((input[index] - 48) * WEIGHTS[index % 4]) % 10;
    const checksum = 10 - @mod(subtotal, 10);
    return if (checksum == @mod(number, 10)) 1 else 0;
}
