package langtons_ant
import "core:c"
@(export)
langtons_ant :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=1||v[0]<0||v[0]>6{return -1};b:[25]bool;for i:=0;i<25;i+=1{b[i]=true};x:=i64(2);y:=i64(2);d:=i64(3);dx:=[4]i64{-1,0,1,0};dy:=[4]i64{0,1,0,-1};for s:=i64(0);s<v[0];s+=1{old:=x*5+y;if b[old]{d=(d+1)%4}else{d=(d+3)%4};x+=dx[d];y+=dy[d];b[old]=!b[old]};mask:=i64(0);for i:=i64(0);i<25;i+=1{if !b[i]{mask|=i64(1)<<i}};return mask|((x*5+y)<<25)|(d<<30)}
