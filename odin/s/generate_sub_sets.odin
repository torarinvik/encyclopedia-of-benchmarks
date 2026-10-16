package generate_sub_sets
import "core:c"

Max_Items :: 12
Max_Safe :: i64(9_007_199_254_740_991)
put32 :: proc "contextless" (output:[^]u8, pos:^usize, value:u32) { bits:=value; for i:usize=0;i<4;i+=1 { output[pos^]=u8(bits&255); pos^+=1; bits>>=8 } }
put64 :: proc "contextless" (output:[^]u8, pos:^usize, value:i64) { bits:=u64(value); for i:usize=0;i<8;i+=1 { output[pos^]=u8(bits&255); pos^+=1; bits>>=8 } }

@(export)
generate_sub_sets :: proc "c" (input:[^]i64, length:c.size_t, output:[^]u8, capacity:c.size_t) -> i64 {
    if input==nil || length<1 || length>Max_Items+1 do return -1
    n_arg:=input[0]; if n_arg<0 || n_arg>Max_Items do return -1
    n:=usize(n_arg); if length!=n+1 do return -1
    for i:usize=0;i<n;i+=1 { value:=input[i+1]; if value < -Max_Safe || value > Max_Safe do return -1 }
    subsets:=usize(1)<<n
    total_items:=usize(0); if n>0 do total_items=n*(subsets/2)
    needed:=4+4*subsets+8*total_items
    if output==nil || capacity<needed do return -2
    pos:usize=0; put32(output,&pos,u32(subsets))
    for mask:usize=0;mask<subsets;mask+=1 {
        count:u32=0
        for j:usize=0;j<n;j+=1 { if (mask & (usize(1)<<j))!=0 do count+=1 }
        put32(output,&pos,count)
        for j:usize=0;j<n;j+=1 { if (mask & (usize(1)<<j))!=0 do put64(output,&pos,input[j+1]) }
    }
    return i64(pos)
}
