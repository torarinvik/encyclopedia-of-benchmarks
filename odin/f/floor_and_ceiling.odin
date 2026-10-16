package floor_and_ceiling
import "core:c"
put_i64_le :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
    bits:=u64(value)
    for b:=0;b<8;b+=1 {out[offset+b]=u8(bits>>u64(8*b))}
}
@(export)
floor_and_ceiling :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil || length<3 || length>384 do return -1
    raw_n,root,key:=input[0],input[1],input[2]
    if raw_n<0 || raw_n>127 || key < -1_000_000 || key>1_000_000 || length!=c.size_t(3+3*raw_n) do return -1
    n:=int(raw_n)
    if (n==0 && root!=-1)||(n>0 && (root<0 || root>=raw_n)) do return -1
    floor,ceiling:=i64(-9223372036854775808),i64(-9223372036854775808)
    current:=n
    if n>0 do current=int(root)
    for step:=0;step<n && current<n;step+=1 {
        base:=3+3*current;value,left,right:=input[base],input[base+1],input[base+2]
        if value < -1_000_000 || value>1_000_000 || left < -1 || right < -1 || left>=raw_n || right>=raw_n do return -1
        if value==key {floor=value;ceiling=value;break}
        if key<value {ceiling=value;if left<0 {current=n}else{current=int(left)}}
        else {floor=value;if right<0 {current=n}else{current=int(right)}}
    }
	if output==nil || capacity<16 do return -2
	put_i64_le(output,0,floor);put_i64_le(output,8,ceiling);return 16
}
