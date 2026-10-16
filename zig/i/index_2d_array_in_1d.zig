/// Retrieve one row-major flattened index from a rectangular matrix.
pub export fn index_2d_array_in_1d(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4) return -1;
    const rows=input[0]; const cols=input[1]; const index=input[2];
    if (rows < 1 or rows > 32 or cols < 1 or cols > 32) return -1;
    const cells: usize=@intCast(rows*cols);
    if (length != cells+3 or index < 0 or index >= rows*cols) return -1;
    const values=input[3..][0..cells];
    for (values) |value| { if (value < 0 or value > 1_000_000) return -1; }
    const row: usize=@intCast(@divTrunc(index,cols));
    const col: usize=@intCast(@rem(index,cols));
    return values[row*@as(usize,@intCast(cols))+col];
}
