package least_square_approx
import "core:c"
rnd :: proc(a,b:i64)->i64{q:=(abs(a)*100000+b/2)/b;if a<0{return -q};return q}
@(export) least_square_approx :: proc "c"(v:[^]i64,n:c.size_t)->i64{if n<5||n>13{return -1};k:=v[0];if k<2||k>6||n!=1+2*k{return -1};sx,sy,sxx,sxy:i64=0,0,0,0;for i:i64=0;i<k;i+=1{x,y:=v[1+2*i],v[2+2*i];if x < -20||x>20||y < -20||y>20{return -1};sx+=x;sy+=y;sxx+=x*x;sxy+=x*y};den:=k*sxx-sx*sx;if den<=0{return -1};num:=k*sxy-sx*sy;sl,it:=rnd(num,den),rnd(sy*den-num*sx,k*den);o,r:i64=100000001,200000003;if sl<=-o||sl>=o||it<=-o||it>=o{return -1};return (sl+o)*r+(it+o)}
