const std = @import("std");

const MaxInput: usize = 67;
const MaxOutput: usize = 504;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn min_plus_convolution_convex_arbitrary(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0=input[0]; const m0=input[1];
    if (n0 < 1 or n0 > 32 or m0 < 1 or m0 > 32) return -1;
    const n:usize=@intCast(n0); const m:usize=@intCast(m0);
    if (length != 2+n+m) return -1;
    const words = input[0..length];
    const a=words[2..2+n]; const b=words[2+n..2+n+m];
    for (words[2..]) |x| if (x<0 or x>1_000_000_000) return -1;
    for (0..n) |i| { if (i+2<n and a[i+1]-a[i]>a[i+2]-a[i+1]) return -1; }
    const count=n+m-1; const bytes=8*count;
    if (bytes>MaxOutput) return -1;
    if (output_opt==null or capacity<bytes) return -2;
    const output=output_opt.?;
    var result:[63]i64=undefined;
    var stack:[128][4]usize=undefined; var top:usize=1;
    stack[0]=.{0,count-1,0,m-1};
    while (top>0) {
        top-=1; const left=stack[top][0]; const right=stack[top][1];
        const ol=stack[top][2]; const or=stack[top][3];
        if (left>right) continue;
        const mid=left+(right-left)/2;
        const low=@max(ol, if (mid>n-1) mid-(n-1) else 0);
        const high=@min(@min(or,m-1),mid);
        var best:i64=std.math.maxInt(i64); var best_j=low;
        for (low..high+1) |j| { const value=a[mid-j]+b[j]; if (value<best) {best=value;best_j=j;} }
        result[mid]=best;
        if (mid<right) {stack[top]=.{mid+1,right,best_j,or};top+=1;}
        if (left<mid) {stack[top]=.{left,mid-1,ol,best_j};top+=1;}
    }
    for (0..count) |i| storeI64Le(output,8*i,result[i]);
    return @intCast(bytes);
}

