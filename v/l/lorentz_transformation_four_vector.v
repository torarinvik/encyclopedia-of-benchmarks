module lorentz_transformation_four_vector
import math
@[export: 'lorentz_transformation_four_vector']
pub fn lorentz_transformation_four_vector(v &i64,n usize)f64{if n!=6{return -1e300};vel:=unsafe{v[0]};s:=unsafe{v[1]};t:=unsafe{v[2]};x:=unsafe{v[3]};y:=unsafe{v[4]};z:=unsafe{v[5]};if vel<1||vel>200000000||s<0||s>3||t< -1000000||t>1000000||x< -100000000||x>100000000||y< -100000000||y>100000000||z< -100000000||z>100000000{return -1e300};b:=f64(vel)/299792458.0;g:=1/math.sqrt(1-b*b);ct:=(f64(t)/1e6)*299792458.0;xx:=f64(x)/100;yy:=f64(y)/100;zz:=f64(z)/100;out:=[4]f64{g*ct-g*b*xx,-g*b*ct+g*xx,yy,zz};return out[s]}
