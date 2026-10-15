const D = [_]u8{
    0,1,2,3,4,5,6,7,8,9, 1,2,3,4,0,6,7,8,9,5,
    2,3,4,0,1,7,8,9,5,6, 3,4,0,1,2,8,9,5,6,7,
    4,0,1,2,3,9,5,6,7,8, 5,9,8,7,6,0,4,3,2,1,
    6,5,9,8,7,1,0,4,3,2, 7,6,5,9,8,2,1,0,4,3,
    8,7,6,5,9,3,2,1,0,4, 9,8,7,6,5,4,3,2,1,0,
};
const P = [_]u8{
    0,1,2,3,4,5,6,7,8,9, 1,5,7,6,2,8,3,0,9,4,
    5,8,0,3,7,9,6,1,4,2, 8,9,1,6,0,4,3,5,2,7,
    9,4,5,3,1,2,6,8,7,0, 4,2,8,6,5,7,3,9,0,1,
    2,7,9,3,8,0,6,4,1,5, 7,0,4,6,9,1,3,2,5,8,
};

export fn verhoeff(digits: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 1024) return -1;
    for (0..length) |index| {
        if (digits[index] < 0 or digits[index] > 9) return -1;
    }
    var checksum: usize = 0;
    for (0..length) |index| {
        const digit: usize = @intCast(digits[length - index - 1]);
        const permutation: usize = P[(index % 8) * 10 + digit];
        checksum = @intCast(D[checksum * 10 + permutation]);
    }
    return if (checksum == 0) 1 else 0;
}
