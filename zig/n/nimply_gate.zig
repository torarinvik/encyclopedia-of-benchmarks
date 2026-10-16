export fn nimply_gate(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const a = values[0];
    const b = values[1];
    if ((a != 0 and a != 1) or (b != 0 and b != 1)) return -1;
    return if (a == 1 and b == 0) 1 else 0;
}
