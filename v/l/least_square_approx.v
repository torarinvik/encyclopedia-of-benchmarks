module least_square_approx
fn rnd(a i64,b i64)i64{q:=(a.abs()*100000+b/2)/b;if a<0{return -q};return q}
@[export: 'least_square_approx']
pub fn least_square_approx(v &i64,n usize)i64{if n<5||n>13{return -1};k:=unsafe{v[0]};if k<2||k>6||n!=usize(1+2*k){return -1};mut sx:=i64(0);mut sy:=i64(0);mut sxx:=i64(0);mut sxy:=i64(0);for i in 0..int(k){x:=unsafe{v[1+2*i]};y:=unsafe{v[2+2*i]};if x < -20||x>20||y < -20||y>20{return -1};sx+=x;sy+=y;sxx+=x*x;sxy+=x*y};den:=k*sxx-sx*sx;if den<=0{return -1};num:=k*sxy-sx*sy;sl:=rnd(num,den);it:=rnd(sy*den-num*sx,k*den);o:=i64(100000001);r:=i64(200000003);if sl<=-o||sl>=o||it<=-o||it>=o{return -1};return (sl+o)*r+(it+o)}
