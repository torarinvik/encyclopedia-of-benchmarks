export fn multiplexer(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 3) return -1;
    const input0 = values[0];
    const input1 = values[1];
    const select = values[2];
    if ((input0 != 0 and input0 != 1) or (input1 != 0 and input1 != 1) or
        (select != 0 and select != 1)) return -1;
    return if (select == 1) input1 else input0;
}
