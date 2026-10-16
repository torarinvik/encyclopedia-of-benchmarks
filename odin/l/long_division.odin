package long_division
import "core:c"
core :: proc(a0,b0:i64)->i64{if b0==0{return 0};neg:=(a0<0)!=(b0<0);a:=a0;b:=b0;if a<0{a=-a};if b<0{b=-b};ds:[16]i64;n:=0;if a==0{n=1};for a>0{ds[n]=a%10;a/=10;n+=1};rem:=i64(0);q:=i64(0);for n>0{n-=1;rem=rem*10+ds[n];d:=i64(0);for rem>=b{rem-=b;d+=1};q=q*10+d};if neg{return -q};return q}
@(export)
long_division :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=2||v[0]<-1000000||v[0]>1000000||v[1]<-10000||v[1]>10000{return -1};return core(v[0],v[1])}
