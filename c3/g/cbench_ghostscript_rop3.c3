module cbench_ghostscript_rop3;

// Independent bounded ROP3 profile; full AFPL v5 terms are in package LICENSE.txt.
fn long cbench_ghostscript_rop3(long* values, usz length) @export("cbench_ghostscript_rop3") {
    if (length > 5 || (length != 0 && values == null) || length != 4) return -1;
    for (usz i = 0; i < 3; i++) if (values[i] < 0 || values[i] > 4294967295) return -1;
    if (values[3] < 0 || values[3] > 255) return -1;
    ulong d=(ulong)values[0], s=(ulong)values[1], t=(ulong)values[2], code=(ulong)values[3];
    ulong result=0;
    for (usz bit=0; bit<32; bit++) {
        ulong index=((t >> bit)&1)<<2 | ((s >> bit)&1)<<1 | ((d >> bit)&1);
        if (((code >> index)&1)!=0) result |= (ulong)1 << bit;
    }
    return (long)result;
}
