/// Emit the nearest strictly smaller value to the left of every input value.
fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}
pub export fn next_smaller_element(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or input[0] < 0 or input[0] > 1024) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n+1) return -1;
    const values=input[1..][0..n];
    for (values) |v| { if (v < -2147483648 or v > 2147483647) return -1; }
    if (capacity<n*8 or (n>0 and output==null)) return -2;
    var stack: [1024]i64 = @splat(0); var top: usize=0;
    for (values,0..) |value,i| {
        while (top>0 and stack[top-1]>=value) top-=1;
        putI64Le(output,i*8,if (top>0) stack[top-1] else -1);
        stack[top]=value; top+=1;
    }
    return @intCast(n*8);
}
