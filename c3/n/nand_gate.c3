module nand_gate;

// 1 only when at least one input is 0; 0 when both are 1.
fn long nand_gate(ulong left, ulong right) @export("nand_gate")
{
    return (long)(1 - (left & right));
}
