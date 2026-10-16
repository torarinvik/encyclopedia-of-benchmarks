package generate_subsets_recursive

import "core:c"

Max_Items :: 12
put32 :: proc "contextless" (output:[^]u8, pos:^usize, value:u32) { bits:=value; for i:usize=0;i<4;i+=1 { output[pos^]=u8(bits&255); pos^+=1; bits>>=8 } }
emit_subsets :: proc "contextless" (input:[^]i64, n:usize, index:usize, mask:u64, selected:u32, output:[^]u8, pos:^usize) {
    if index==n {
        put32(output,pos,selected)
        for i:usize=0;i<n;i+=1 { if (mask & (u64(1)<<i))!=0 { output[pos^]=u8(input[i+1]); pos^+=1 } }
        return
    }
    emit_subsets(input,n,index+1,mask|(u64(1)<<index),selected+1,output,pos)
    emit_subsets(input,n,index+1,mask,selected,output,pos)
}

@(export)
generate_subsets_recursive :: proc "c" (input:[^]i64, length:c.size_t, output:[^]u8, capacity:c.size_t) -> i64 {
    if input==nil || length<1 || length>Max_Items+1 do return -1
    n_arg:=input[0]; if n_arg<0 || n_arg>Max_Items do return -1
    n:=usize(n_arg); if length!=n+1 do return -1
    for i:usize=0;i<n;i+=1 { value:=input[i+1]; if value<0 || value>127 do return -1 }
    subsets:=usize(1)<<n
    needed:=4+4*subsets+n*(subsets/2)
    if output==nil || capacity<needed do return -2
    pos:usize=0; put32(output,&pos,u32(subsets))
    emit_subsets(input,n,0,0,0,output,&pos)
    return i64(pos)
}
