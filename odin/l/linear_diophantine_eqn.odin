package linear_diophantine_eqn
import "core:c"
gcdv :: proc(a0,b0:i64)->i64{a:=a0;b:=b0;if a<0{a=-a};if b<0{b=-b};for b!=0{r:=a%b;a=b;b=r};return a}
@(export)
linear_diophantine_eqn :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n!=3||v[0]<-100000||v[0]>100000||v[1]==0||v[1]<-100000||v[1]>100000||v[2]<-1000000||v[2]>1000000{return -1};if v[2]%gcdv(v[0],v[1])==0{return 1};return 0}
