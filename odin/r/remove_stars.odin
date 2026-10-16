package remove_stars
import "core:c"
@(export)
remove_stars :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<1||n>4097||v[0]<0||v[0]>4096||n!=c.size_t(v[0]+1) do return -1
 result:=0
 for i:=0;i<int(v[0]);i+=1 {if v[i+1]<0||v[i+1]>127 do return -1;if v[i+1]==42 {if result>0 do result-=1}else{result+=1}}
 if c.size_t(result)>cap||(result>0&&out==nil) do return -2
 w:=0
 for i:=0;i<int(v[0]);i+=1 {if v[i+1]==42 {if w>0 do w-=1}else{out[w]=u8(v[i+1]);w+=1}}
 return i64(w)
}
