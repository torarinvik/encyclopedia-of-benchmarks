export fn three_way_partition(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 2 or length > 258) return -1;
    const n=input[0]; const pivot=input[1]; if(n<0 or n>256 or length!=@as(usize,@intCast(n))+2 or pivot<std.math.minInt(i32) or pivot>std.math.maxInt(i32))return -1;
    var a:[256]i32=undefined;for(0..@as(usize,@intCast(n)))|i|{const x=input[i+2];if(x<std.math.minInt(i32) or x>std.math.maxInt(i32))return -1;a[i]=@intCast(x);}
    var low:usize=0;var mid:usize=0;var high:usize=@intCast(n);while(mid<high){if(a[mid]<pivot){const t=a[low];a[low]=a[mid];a[mid]=t;low+=1;mid+=1;}else if(a[mid]>pivot){high-=1;const t=a[mid];a[mid]=a[high];a[high]=t;}else mid+=1;}
    const bytes=(@as(usize,@intCast(n))+2)*4;if(capacity<bytes)return -2;for(0..@as(usize,@intCast(n)))|i|{const b=std.mem.toBytes(a[i]);@memcpy(output[i*4..][0..4],&b);}const bounds=[2]i32{@intCast(low),@intCast(high)};for(0..2)|j|{const b=std.mem.toBytes(bounds[j]);@memcpy(output[(n+@as(i64,@intCast(j)))*4..][0..4],&b);}return n+2;
}
const std=@import("std");
