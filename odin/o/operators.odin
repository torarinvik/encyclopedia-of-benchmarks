package operators
import "core:c"
put_i32 :: proc(outp:[^]u8,off:int,x:i64){bits:=u32(i32(x));for k:=0;k<4;k+=1{outp[off+k]=u8(bits>>u32(8*k))}}
@(export)
operators :: proc "c"(v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<5 do return -1;op,ra,ca:=v[0],v[1],v[2];if(op!=0&&op!=1)||ra<1||ra>16||ca<0||ca>16||ra*ca>256 do return -1;count:=int(ra*ca);pb:=3+count;if n<c.size_t(pb+2)do return -1;rb,cb:=v[pb],v[pb+1];if rb<1||rb>16||cb<0||cb>16||rb*cb>256||n!=c.size_t(pb+2+rb*cb)do return -1
 for i:=0;i<count;i+=1{if v[3+i] < -1000000||v[3+i]>1000000 do return -1};for i:=0;i<int(rb*cb);i+=1{if v[pb+2+i] < -1000000||v[pb+2+i]>1000000 do return -1};if ra!=rb||ca!=cb do return -1;bytes:=count*4;if cap<c.size_t(bytes)||(bytes>0&&outp==nil)do return -2;for i:=0;i<count;i+=1{a,b:=v[3+i],v[pb+2+i];put_i32(outp,i*4,if op==0{a+b}else{a-b})};return i64(count)
}
