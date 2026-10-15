module xor_gate;

// 1 when the inputs differ; otherwise 0.
fn long xor_gate(ulong left, ulong right) @export("xor_gate")
{
    return (long)(left ^ right);
}
