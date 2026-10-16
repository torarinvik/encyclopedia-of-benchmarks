const MAX_LENGTH: usize = 7;
const BYTES_PER_VALUE: usize = 4;
fn putI32(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |b| output[offset+b] = @truncate(bits >> @as(u5, @intCast(8*b)));
}
fn generate(values: *[MAX_LENGTH]i32, n: usize, k: usize, output: [*c]u8, rows: *usize) void {
    if (k == 1) {
        const start=rows.* * n * BYTES_PER_VALUE;
        for (0..n) |j| putI32(output,start+j*BYTES_PER_VALUE,values[j]);
        rows.* += 1;
        return;
    }
    for (0..k) |i| {
        const swap_index=if(k%2==0)i else 0;
        const temp=values[swap_index];values[swap_index]=values[k-1];values[k-1]=temp;
        generate(values,n,k-1,output,rows);
    }
}
pub export fn heap_permutation(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if(input==null||length<1||length>MAX_LENGTH+1)return -1;
    const nv=input[0];if(nv<0 or nv>7 or length!=@as(usize,@intCast(nv))+1)return -1;
    const n:usize=@intCast(nv);var values=[_]i32{0}**MAX_LENGTH;
    for(0..n)|i|{const value=input[i+1];if(value< -2147483648 or value>2147483647)return -1;values[i]=@intCast(value);}
    var permutations:usize=1;for(2..n+1)|factor|permutations*=factor;
    const required=permutations*n*BYTES_PER_VALUE;if(capacity<required||(required!=0 and output==null))return -2;if(n==0)return 1;
    var rows:usize=0;generate(&values,n,n,output,&rows);return @intCast(rows);
}
