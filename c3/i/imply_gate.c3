module imply_gate;

fn long imply_gate(ulong left, ulong right) @export("imply_gate") {
    if (left > 1 || right > 1) return -1;
    return left == 0 || right == 1 ? 1 : 0;
}
