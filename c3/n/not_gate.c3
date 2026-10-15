module not_gate;

// Return the logical complement on the Boolean 0/1 domain.
fn long not_gate(long value) @export("not_gate")
{
    return value == 0 ? 1 : 0;
}
