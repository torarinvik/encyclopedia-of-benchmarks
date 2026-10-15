const MAX_INDEX: i64 = 3_810_777;

export fn tetrahedral_sequence(index: i64) i64 {
    if (index < 0 or index > MAX_INDEX) return -1;
    var a = index;
    var b = index + 1;
    var c = index + 2;
    if (@rem(a, 2) == 0) {
        a = @divTrunc(a, 2);
    } else if (@rem(b, 2) == 0) {
        b = @divTrunc(b, 2);
    } else {
        c = @divTrunc(c, 2);
    }
    if (@rem(a, 3) == 0) {
        a = @divTrunc(a, 3);
    } else if (@rem(b, 3) == 0) {
        b = @divTrunc(b, 3);
    } else {
        c = @divTrunc(c, 3);
    }
    return a * b * c;
}
