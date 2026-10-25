// Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
export fn cbench_ghostscript_rop3_operand_usage(values: [*c]const i64, length: usize) i64 {
    if (length > 2 or (length != 0 and values == null) or length != 1) return -1;
    if (values[0] < 0 or values[0] > 255) return -1;
    const code: u64 = @intCast(values[0]);
    var usage: u64 = 0;
    for (0..3) |dimension| {
        const toggle: usize = @as(usize, 1) << @intCast(dimension);
        for (0..8) |index| {
            if ((index & toggle) == 0 and ((code >> @intCast(index)) & 1) != ((code >> @intCast(index | toggle)) & 1)) {
                usage |= @intCast(toggle);
                break;
            }
        }
    }
    return @intCast(usage);
}
