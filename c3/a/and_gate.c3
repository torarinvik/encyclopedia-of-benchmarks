module and_gate;

// Two-input Boolean AND over the benchmark's 0/1 domain.
fn long and_gate(ulong left, ulong right) @export("and_gate")
{
    return (long)(left & right);
}
