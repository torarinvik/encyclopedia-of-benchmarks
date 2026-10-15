package count_distinct_elements_in_window
import "core:c"
put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits:=transmute(u64)value
    for b:usize=0;b<8;b+=1 { output[offset+b]=u8(bits>>u64(8*b)) }
}
@(export)
count_distinct_elements_in_window :: proc "c" (input: [^]i64, length:c.size_t, output:[^]u8, capacity:c.size_t)->i64 {
    if input==nil || length<3 || input[0]<1 || input[0]>256 do return -1
    n:=usize(input[0]); if input[1]<1 || input[1]>i64(n) || length!=n+2 do return -1
    k:=usize(input[1]); out_n:=n-k+1
    for i:usize=0;i<n;i+=1 {if input[i+2]<-2147483648 || input[i+2]>2147483647 do return -1}
    if capacity<out_n*8 || output==nil do return -2
    keys:[256]i32; counts:[256]i32; used:usize=0; distinct:i64=0
    for i:usize=0;i<k;i+=1 {
        value:=i32(input[i+2]); j:usize=0; for j<used && keys[j]!=value {j+=1}
        if j==used {keys[used]=value;used+=1}; if counts[j]==0 do distinct+=1; counts[j]+=1
    }
    put_i64_le(output,0,distinct)
    for i:=k;i<n;i+=1 {
        incoming:=i32(input[i+2]); j:usize=0; for j<used && keys[j]!=incoming {j+=1}
        if j==used {keys[used]=incoming;used+=1}; if counts[j]==0 do distinct+=1; counts[j]+=1
        outgoing:=i32(input[i-k+2]); j=0; for keys[j]!=outgoing {j+=1}; counts[j]-=1; if counts[j]==0 do distinct-=1
        put_i64_le(output,(i-k+1)*8,distinct)
    }
    return i64(out_n*8)
}
