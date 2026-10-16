module nimply_gate;

fn long nimply_gate(long* values, usz length) @export("nimply_gate") {
    if (values == null || length != 2) return -1;
    long a = values[0]; long b = values[1];
    if ((a != 0 && a != 1) || (b != 0 && b != 1)) return -1;
    return a == 1 && b == 0 ? 1 : 0;
}
