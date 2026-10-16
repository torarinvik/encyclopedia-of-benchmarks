package lorentz_transformation_four_vector
import "core:c"
import "core:math"
lorentz_transformation_four_vector :: proc(v: [^]i64,n:c.size_t)->f64{if n!=6{return -1e300};vel,s,t,x,y,z:=v[0],v[1],v[2],v[3],v[4],v[5];if vel<1||vel>200000000||s<0||s>3||t< -1000000||t>1000000||x< -100000000||x>100000000||y< -100000000||y>100000000||z< -100000000||z>100000000{return -1e300};b:=f64(vel)/299792458.0;g:=1/math.sqrt(1-b*b);ct:=(f64(t)/1e6)*299792458.0;xx:=f64(x)/100;yy:=f64(y)/100;zz:=f64(z)/100;out:=[4]f64{g*ct-g*b*xx,-g*b*ct+g*xx,yy,zz};return out[s]}
