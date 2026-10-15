module or_gate;

// 1 when either input is 1; otherwise 0.
fn long or_gate(ulong left, ulong right) @export("or_gate")
{
    return (long)(left | right);
}
