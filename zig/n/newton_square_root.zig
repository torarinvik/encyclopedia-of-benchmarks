export fn newton_square_root(value: i64) i64 {
    if (value < 0 or value > 4_611_686_018_427_387_903) return -1;
    if (value == 0) return 0;

    const bit_length: i32 = @intFromFloat(@ceil(@log2(@as(f64, @floatFromInt(value)))));
    var root: i64 = @as(i64, 1) << @intCast(@divTrunc(bit_length, 2));
    while (!(value >= root * root and value <= root * root + root + root)) {
        root += @divTrunc(value, root);
        root = @divTrunc(root, 2);
    }
    return root;
}
