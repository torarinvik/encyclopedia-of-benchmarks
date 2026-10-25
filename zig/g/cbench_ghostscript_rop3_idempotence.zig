// Independent bounded profile; full Aladdin Free Public License v5 is bundled.
export fn cbench_ghostscript_rop3_idempotence(values: [*c]const i64, length: usize) i64 {
    if (length > 2 or (length != 0 and values == null) or length != 1) return -1;
    if (values[0] < 0 or values[0] > 255) return -1;
    const code: u64 = @intCast(values[0]);
    var bit: usize = 1;
    while (bit < 8) : (bit += 2) {
        if (((code >> @intCast(bit)) & 1) != 0 and ((code >> @intCast(bit - 1)) & 1) == 0) return 0;
    }
    return 1;
}
