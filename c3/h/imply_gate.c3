module imply_gate;

// Two-input Boolean implication over the benchmark's 0/1 domain.
fn long imply_gate(ulong left, ulong right) @export("imply_gate")
{
    return (left == 0 || right == 1) ? 1 : 0;
}
