package geometric_series
import "core:c"
put_f64_le :: proc "contextless" (value:f64, output:[^]u8, offset:usize) {
    bits:=transmute(u64)value
    for byte:=0;byte<8;byte+=1{output[offset+byte]=u8(bits>>u64(8*byte))}
}
@(export)
geometric_series :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length!=3 do return -1
    if input[0]<0||input[0]>16||input[1]<1||input[1]>8||input[2]<1||input[2]>4 do return -1
    n:=usize(input[0]);if capacity<n*8||(n>0&&output==nil) do return -2
    term:=f64(input[1]);ratio:=f64(input[2])
    for index:usize=0;index<n;index+=1{put_f64_le(term,output,index*8);term*=ratio}
    return i64(n*8)
}
