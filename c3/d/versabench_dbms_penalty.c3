module versabench_dbms_penalty;

fn long versabench_dbms_penalty(long* values, usz length) @export("versabench_dbms_penalty") {
    if (values == null || length < 1 || length > 17 || length != 16) return -1;
    for (usz box = 0; box < 2; box++) for (usz d = 0; d < 4; d++) {
        long lo = values[box*8+d]; long hi = values[box*8+4+d];
        if (lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo >= hi) return -1;
    }
    long joined = 1; long original = 1;
    for (usz d = 0; d < 4; d++) {
        long lo = values[d] < values[8+d] ? values[d] : values[8+d];
        long hi = values[4+d] > values[12+d] ? values[4+d] : values[12+d];
        joined *= hi - lo;
        original *= values[4+d] - values[d];
    }
    return joined - original;
}
