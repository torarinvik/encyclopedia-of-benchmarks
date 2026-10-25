const std=@import("std");
export fn cbench_rsynth_natural_glottal_sample(raw:?[*]const f64,n:usize,raw_out:?[*]f64,cap:usize)i64{
    if(raw==null or n==0 or n>3)return -1;const v=raw.?[0..n];for(v)|x|if(!std.math.isFinite(x))return -1;
    if(n!=2 or v[0]<40.0 or v[0]>263.0 or @trunc(v[0])!=v[0] or v[1]<0.0 or v[1]>299.0 or @trunc(v[1])!=v[1])return -1;
    const nopen:i64=@intFromFloat(v[0]);const index:i64=@intFromFloat(v[1]);var result:f32=0.0;
    if(index<nopen){const b_int:i64=@divTrunc(1_920_000,nopen*nopen);const b:f32=@floatFromInt(b_int);const product:f32=b*@as(f32,@floatFromInt(nopen));var a:f32=@floatCast(@as(f64,product)*0.333);var wave:f32=0.0;var j:i64=0;while(j<=index):(j+=1){a=a-b;wave=wave+a;}result=@floatCast(@as(f64,wave)*0.028);}
    if(raw_out==null or cap<1)return -2;raw_out.?[0]=result;return 1;
}
