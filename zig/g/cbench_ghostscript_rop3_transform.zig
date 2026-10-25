// Independent ROP3 truth-table transforms; full AFPL v5 is bundled.
export fn cbench_ghostscript_rop3_transform(values: [*c]const i64, length: usize) i64 {
    if (length > 3 or (length != 0 and values == null) or length != 2) return -1;
    if (values[0] < 0 or values[0] > 14 or values[1] < 0 or values[1] > 255) return -1;
    const mode: usize = @intCast(values[0]);
    const code: u64 = @intCast(values[1]);
    var result: u64 = 0;
    for (0..8) |index| {
        const d = index & 1;
        const s = (index >> 1) & 1;
        const t = (index >> 2) & 1;
        var source_index = index;
        var forced: ?u64 = null;
        if (mode <= 2) {
            source_index ^= @as(usize, 1) << @intCast(mode);
        } else if (mode <= 8) {
            const dimension = (mode - 3) / 2;
            const pinned = (mode - 3) & 1;
            source_index = (index & ~(@as(usize, 1) << @intCast(dimension))) | (pinned << @intCast(dimension));
        } else if (mode == 9) {
            source_index = (index & ~@as(usize, 6)) | (s << 2) | (t << 1);
        } else if (mode <= 13) {
            const operand = if (mode < 12) s else t;
            if (operand == ((mode - 10) & 1)) forced = @as(u64, @intCast(d));
        } else {
            forced = 1 - ((code >> @intCast(index)) & 1);
        }
        const bit = forced orelse ((code >> @intCast(source_index)) & 1);
        result |= bit << @intCast(index);
    }
    return @intCast(result);
}
