const std = @import("std");
const MAX_ITEMS: usize = 32;
fn bubble(a: *[MAX_ITEMS]i32, n: usize) void { var end=n; while(end>1):(end-=1){var i:usize=0;while(i+1<end):(i+=1){if(a[i+1]<a[i]){std.mem.swap(i32,&a[i],&a[i+1]);}}} }
fn quick(a: *[MAX_ITEMS]i32, n: usize) void {
    if(n<2)return;const pivot=a[0];var lo=[_]i32{0}**MAX_ITEMS;var hi=[_]i32{0}**MAX_ITEMS;var nl:usize=0;var nh:usize=0;
    for(1..n)|i|{if(a[i]<pivot){lo[nl]=a[i];nl+=1;}else{hi[nh]=a[i];nh+=1;}}
    quick(&hi,nh);quick(&lo,nl);var k:usize=0;for(0..nl)|i|{a[k]=lo[i];k+=1;}a[k]=pivot;k+=1;for(0..nh)|i|{a[k]=hi[i];k+=1;}
}
export fn mccat_qbsort(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<3 or length>2+MAX_ITEMS)return -1;const input=input_opt.?;const mode=input[0];const cv=input[1];
    if((mode!=0 and mode!=1) or cv<1 or cv>MAX_ITEMS)return -1;const n:usize=@intCast(cv);if(length!=n+2)return -1;
    var a=[_]i32{0}**MAX_ITEMS;for(0..n)|i|{if(input[i+2]<std.math.minInt(i32) or input[i+2]>std.math.maxInt(i32))return -1;a[i]=@intCast(input[i+2]);}
    for(0..1000)|_|{for(0..n)|i|{a[i]=@intCast(input[i+2]);}if(mode==0)bubble(&a,n) else quick(&a,n);}
    const need=4*n;const output=output_opt orelse return -2;if(capacity<need)return -2;for(0..n)|i|{const bits:u32=@bitCast(a[i]);for(0..4)|b|output[4*i+b]=@truncate(bits>>@as(u5,@intCast(8*b)));}return @intCast(need);
}
