const START: i64 = 138_902_663;
const MINIMUM: i64 = 101_010_103;

fn isSquareForm(input: i64) bool {
    var value = input;
    var digit: i64 = 9;
    while (value > 0) {
        if (@rem(value, 10) != digit) return false;
        value = @divTrunc(value, 100);
        digit -= 1;
    }
    return true;
}

export fn problem206(unused: i64) i64 {
    if (unused != 0) return -1;
    var candidate = START;
    while (candidate >= MINIMUM) {
        if (isSquareForm(candidate * candidate)) return candidate * 10;
        candidate -= if (@rem(candidate, 10) == 3) 6 else 4;
    }
    return -1;
}
