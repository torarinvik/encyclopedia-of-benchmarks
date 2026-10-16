package pi_generator
import "core:c"
mix :: proc(h:u32,b:u8)->u32{return u32((u64(h^u32(b))*16777619)&0xFFFFFFFF)}
@(export)
pi_generator :: proc "c" (digits:i64)->i64{if digits<0||digits>8 do return -1;q:=i64(1);r:=i64(0);t:=i64(1);k:=i64(1);n:=i64(3);m:=i64(3);counter:=i64(0);h:=u32(2166136261);for counter!=digits+1{if 4*q+r-t<n*t{h=mix(h,u8(48+n));if counter==0 do h=mix(h,u8('.'));if digits==counter do break;counter+=1;nr:=10*(r-n*t);n=(10*(3*q+r))/t-10*n;q*=10;r=nr}else{nr:=(2*q+r)*m;nn:=(q*(7*k)+2+r*m)/(t*m);q*=k;t*=m;m+=2;k+=1;n=nn;r=nr}};return i64(h)}
