module cbench_ghostscript_rop3_operand_usage;

// Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
fn long cbench_ghostscript_rop3_operand_usage(long* values, usz length) @export("cbench_ghostscript_rop3_operand_usage") {
    if (length > 2 || (length != 0 && values == null) || length != 1) return -1;
    if (values[0] < 0 || values[0] > 255) return -1;
    ulong code=(ulong)values[0];
    uint usage=0;
    for (uint dimension=0; dimension<3; dimension++) {
        uint toggle=1u<<dimension;
        for (uint index=0; index<8; index++) {
            if ((index&toggle)==0 && ((code>>index)&1)!=((code>>(index|toggle))&1)) { usage|=toggle; break; }
        }
    }
    return (long)usage;
}
