package pack_consecutive_repetitions_in_sublist
import "core:c"
mix :: proc "contextless" (h:u32,b:u8)->u32{return u32((u64(h^u32(b))*16777619)&0xFFFFFFFF)}
feed :: proc "contextless" (h0:u32,x:u32)->u32{h:=h0;for shift:=0;shift<32;shift+=8{h=mix(h,u8(x>>u32(shift)))};return h}
@(export)
pack_consecutive_repetitions_in_sublist :: proc "c" (v:[^]i64,n:c.size_t)->i64{
 if v==nil||n<1||n>65||v[0]<0||v[0]>64||n!=c.size_t(v[0]+1) do return -1
 count:=int(v[0]);for i:=0;i<count;i+=1{if v[i+1]< -2147483648||v[i+1]>2147483647 do return -1}
 h:=u32(2166136261);i:=0
 for i<count{value:=i32(v[i+1]);j:=i+1;for j<count&&v[j+1]==i64(value){j+=1};h=feed(h,u32(value));h=feed(h,u32(j-i));i=j}
 return i64(h)
}
