package hill_encoder
import "core:c"
@(export)
hill_encoder :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64 {
 if v==nil||n<10||n>74 do return -1
 if v[0]<0||v[0]>64||n!=c.size_t(10+v[0]) do return -1
 length:=int(v[0]);padded:=(length+2)/3*3
 var text:[66]i64;var key:[9]i64;var result:[66]i64
 for i in 0..<length {if v[1+i]<65||v[1+i]>90 do return -1;text[i]=v[1+i]}
 for i in length..<padded {text[i]=32}
 for i in 0..<9 {key[i]=v[1+length+i];if key[i]<-2||key[i]>2 do return -1}
 for off:=0;off<padded;off+=3 {for row in 0..<3 {sum:=i64(0);for col in 0..<3 {sum+=key[row*3+col]*text[off+col]};if sum<0||sum>65535 do return -1;result[off+row]=sum}}
 bytes:=padded*8;if out==nil||cap<c.size_t(bytes) do return -2
 for i in 0..<padded {bits:=transmute(u64)result[i];for k in 0..<8 {out[i*8+k]=u8(bits>>(8*k))}}
 return i64(bytes)
}
