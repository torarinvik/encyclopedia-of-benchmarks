module versabench_dbms_consistent_key;
fn long versabench_dbms_consistent_key(long* values, usz length) @export("versabench_dbms_consistent_key") {
    if (values == null || length < 1 || length > 17 || length != 16) return -1;
    for (usz box = 0; box < 2; box++) for (usz d = 0; d < 4; d++) {
        usz base = box * 8; long lower = values[base+d]; long upper = values[base+4+d];
        if (lower < -8 || lower > 8 || upper < -8 || upper > 8 || lower > upper) return -1;
    }
    for (usz d = 0; d < 4; d++) if (values[d] > values[12+d] || values[8+d] > values[4+d]) return 0;
    return 1;
}
