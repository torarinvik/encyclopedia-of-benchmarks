fn pack(n: i32, d: i32) i64 { return @bitCast((@as(u64,@as(u32,@bitCast(n))) << 32) | @as(u32,@bitCast(d))); }
fn mul(a: i32,b: i32) i32 { return @bitCast(@as(u32,@bitCast(a)) *% @as(u32,@bitCast(b))); }
fn add(a: i32,b: i32) i32 { return @bitCast(@as(u32,@bitCast(a)) +% @as(u32,@bitCast(b))); }
export fn adtfraction(raw: [*]const i64, length: usize) i64 {
    if(length!=5)return -1;const a=raw[0..5];for(a)|v|{if(v < -100000 or v > 100000)return -1;}
    if(a[0]<0 or a[0]>4)return -1;const op:i32=@intCast(a[0]);const n:i32=@intCast(a[1]);const d:i32=@intCast(a[2]);const m:i32=@intCast(a[3]);const e:i32=@intCast(a[4]);
    if(op==0){if(d==0 or e==0)return -1;const den=mul(d,e);if(den==0)return -1;return pack(add(mul(d,m),mul(n,e)),den);}
    if(op==1){if(d==0)return -1;return pack(mul(n,m),d);}
    if(op==2){if(d==0 or e==0)return -1;const den=mul(d,e);if(den==0)return -1;return pack(mul(n,m),den);}
    if(op==3){if(n==0)return -1;return pack(d,n);}
    if(d==0)return -1;const value=@as(f32,@floatFromInt(n))/@as(f32,@floatFromInt(d));return @intCast(@as(u32,@bitCast(value)));
}
