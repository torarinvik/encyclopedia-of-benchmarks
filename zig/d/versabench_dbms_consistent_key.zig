export fn versabench_dbms_consistent_key(raw: [*c]const i64, length: usize) i64 {
    if (raw == null or length < 1 or length > 17 or length != 16) return -1;
    const values: [*]const i64 = raw;
    for (0..2) |box| {
        const base = box * 8;
        for (0..4) |d| {
            const lower = values[base+d]; const upper = values[base+4+d];
            if (lower < -8 or lower > 8 or upper < -8 or upper > 8 or lower > upper) return -1;
        }
    }
    for (0..4) |d| if (values[d] > values[12+d] or values[8+d] > values[4+d]) return 0;
    return 1;
}
