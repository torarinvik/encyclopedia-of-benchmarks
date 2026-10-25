module cbench_ghostscript_rop3_transform;

// Independent ROP3 truth-table transforms; complete AFPL v5 is bundled.
fn long cbench_ghostscript_rop3_transform(long* values, usz length) @export("cbench_ghostscript_rop3_transform") {
    if (length > 3 || (length != 0 && values == null) || length != 2) return -1;
    if (values[0] < 0 || values[0] > 14 || values[1] < 0 || values[1] > 255) return -1;
    uint mode=(uint)values[0]; ulong code=(ulong)values[1]; ulong result=0;
    for (uint index=0; index<8; index++) {
        uint d=index&1, s=(index>>1)&1, t=(index>>2)&1;
        uint source_index=index; int forced=-1;
        if (mode<=2) source_index^=1u<<mode;
        else if (mode<=8) { uint dimension=(mode-3)/2, pinned=(mode-3)&1; source_index=(index&~(1u<<dimension))|(pinned<<dimension); }
        else if (mode==9) source_index=(index&~6u)|(s<<2)|(t<<1);
        else if (mode<=13) { uint operand=mode<12?s:t, required=(mode-10)&1; if (operand==required) forced=(int)d; }
        else forced=1-(int)((code>>index)&1);
        uint bit=forced<0?(uint)((code>>source_index)&1):(uint)forced;
        result|=(ulong)bit<<index;
    }
    return (long)result;
}
