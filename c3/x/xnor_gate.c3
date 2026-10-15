module xnor_gate;

// 1 when the inputs are equal; otherwise 0.
fn long xnor_gate(ulong left, ulong right) @export("xnor_gate")
{
    return (long)(1 - (left ^ right));
}
