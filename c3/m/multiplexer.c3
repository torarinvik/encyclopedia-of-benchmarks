module multiplexer;

fn long multiplexer(long* values, usz length) @export("multiplexer") {
    if (values == null || length != 3) return -1;
    long input0 = values[0];
    long input1 = values[1];
    long select = values[2];
    if ((input0 != 0 && input0 != 1) || (input1 != 0 && input1 != 1) ||
        (select != 0 && select != 1)) return -1;
    return select == 1 ? input1 : input0;
}
