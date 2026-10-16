package pareto_optimization
import "core:c"
OFFSET::u64(0xcbf29ce484222325);PRIME::u64(0x100000001b3)
feed::proc(h:u64,v:i64)->u64{bits:=transmute(u64(v));for s:=0;s<64;s+=8{h=(h^u64(u8(bits>>u32(s))))*PRIME};return h}
@(export)
pareto_optimization::proc "c" (a:[^]i64,len:c.size_t)->i64{if a==nil||len<2||len>514 do return -1;r64,c64:=a[0],a[1];if r64<1||r64>64||c64<1||c64>8||len!=c.size_t(2+r64*c64)do return -1;r,c:=int(r64),int(c64);for k:=0;k<r*c;k+=1{if a[2+k]<-1000||a[2+k]>1000 do return -1};var keep:[64]bool;kept:=i64(0);for i:=0;i<r;i+=1{keep[i]=true;for j:=0;j<r;j+=1{if i==j do continue;ge,gt:=true,false;for x:=0;x<c;x+=1{l,v:=a[2+j*c+x],a[2+i*c+x];if l<v do ge=false;if l>v do gt=true};if ge&&(gt||j<i){keep[i]=false;break}};if keep[i]do kept+=1};h:=feed(OFFSET,kept);h=feed(h,c64);for i:=0;i<r;i+=1{if keep[i]{for x:=0;x<c;x+=1{h=feed(h,a[2+i*c+x])}}};return i64(h&0x7fffffffffffffff)}
