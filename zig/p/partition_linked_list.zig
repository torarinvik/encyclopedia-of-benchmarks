const MOD: i64 = 1000000007;
const BASE: i64 = 2000000003;
export fn partition_linked_list(v: [*c]const i64, n: usize) i64 {
    if (v == null or n < 2 or n > 66 or v[0] < 0 or v[0] > 64 or n != @as(usize, @intCast(v[0])) + 2 or v[1] < -2147483648 or v[1] > 2147483647) return -1;
    const count: usize = @intCast(v[0]); var less: [64]i64 = undefined; var ge: [64]i64 = undefined; var l: usize = 0; var g: usize = 0;
    for (0..count) |i| { const x=v[i+2]; if (x < -2147483648 or x > 2147483647) return -1; if(x<v[1]){less[l]=x;l+=1;}else{ge[g]=x;g+=1;} }
    var h:i64=0; for(less[0..l])|x| h=@mod(h*BASE+x+2147483648,MOD); for(ge[0..g])|x| h=@mod(h*BASE+x+2147483648,MOD); return h;
}
