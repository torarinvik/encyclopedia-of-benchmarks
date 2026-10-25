module cbench_ghostscript_rop3_idempotence;

// Independent bounded profile; complete Aladdin Free Public License v5 is bundled.
fn long cbench_ghostscript_rop3_idempotence(long* values, usz length) @export("cbench_ghostscript_rop3_idempotence") {
    if (length > 2 || (length != 0 && values == null) || length != 1) return -1;
    if (values[0] < 0 || values[0] > 255) return -1;
    ulong code=(ulong)values[0];
    for (usz bit=1; bit<8; bit+=2)
        if (((code >> bit)&1)!=0 && ((code >> (bit-1))&1)==0) return 0;
    return 1;
}
