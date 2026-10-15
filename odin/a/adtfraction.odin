package adtfraction

import "core:c"

wrap_add :: proc(a,b:i32)->i32 { return transmute(i32)(transmute(u32)a + transmute(u32)b) }
wrap_mul :: proc(a,b:i32)->i32 { return transmute(i32)(transmute(u32)a * transmute(u32)b) }
pack :: proc(n,d:i32)->i64 { return transmute(i64)((u64(transmute(u32)n)<<32)|u64(transmute(u32)d)) }

@(export)
adtfraction :: proc "c" (input:[^]i64, length:c.size_t)->i64 {
    if length != 5 do return -1
    for i:=0;i<5;i+=1 { if input[i] < -100000 || input[i] > 100000 do return -1 }
    if input[0] < 0 || input[0] > 4 do return -1
    op,n,d,m,e:=i32(input[0]),i32(input[1]),i32(input[2]),i32(input[3]),i32(input[4])
    if op==0 { if d==0||e==0 do return -1; den:=wrap_mul(d,e); if den==0 do return -1; return pack(wrap_add(wrap_mul(d,m),wrap_mul(n,e)),den) }
    if op==1 { if d==0 do return -1; return pack(wrap_mul(n,m),d) }
    if op==2 { if d==0||e==0 do return -1; den:=wrap_mul(d,e); if den==0 do return -1; return pack(wrap_mul(n,m),den) }
    if op==3 { if n==0 do return -1; return pack(d,n) }
    if d==0 do return -1
    value:=f32(n)/f32(d); return i64(transmute(u32)value)
}
