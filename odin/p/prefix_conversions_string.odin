package prefix_conversions_string
import "core:c"
append_i64 :: proc(out:[^]u8, at0:int, x0:i64)->int{at:=at0;x:=x0;if x<0{out[at]=u8('-');at+=1;x=-x};if x==0{out[at]=u8('0');return at+1};rev:[24]u8;n:=0;for x>0{rev[n]=u8('0'+x%10);n+=1;x/=10};for n>0{n-=1;out[at]=rev[n];at+=1};return at}
raw :: proc(out:[^]u8,x:i64)->i64{return i64(append_i64(out,0,x))}
scaled :: proc(out:[^]u8,x,scale:i64,name:string)->i64{if x%scale!=0 do return -1;at:=append_i64(out,0,x/scale);for c in ".0 "{out[at]=u8(c);at+=1};for c in name{out[at]=u8(c);at+=1};return i64(at)}
@(export)
prefix_conversions_string :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n!=2||(v[0]!=0&&v[0]!=1)||v[1]< -1000000000000||v[1]>1000000000000 do return -1
 if out==nil||cap<8192 do return -2
 x:=v[1];if x<=0 do return raw(out,x)
 if v[0]==0{if x>1000000000{return scaled(out,x,1000000000,"giga")};if x>1000000{return scaled(out,x,1000000,"mega")};if x>1000{return scaled(out,x,1000,"kilo")};if x>100{return scaled(out,x,100,"hecto")};if x>10{return scaled(out,x,10,"deca")}}else{if x>1073741824{return scaled(out,x,1073741824,"giga")};if x>1048576{return scaled(out,x,1048576,"mega")};if x>1024{return scaled(out,x,1024,"kilo")}}
 return raw(out,x)
}
