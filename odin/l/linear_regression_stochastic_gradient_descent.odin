package linear_regression_stochastic_gradient_descent
import "core:c"
INVALID :: -1.0e300
@(export)
linear_regression_stochastic_gradient_descent :: proc "c" (v:[^]i64,length:c.size_t)->f64 {
 if v==nil||length<9||length>133 do return INVALID
 n:=v[0];epochs:=v[1];rate:=v[2];m0:=v[3];b0:=v[4]
 if n<2||n>64||length!=c.size_t(5+2*n)||epochs<1||epochs>200||rate<1||rate>10000||m0< -10000000||m0>10000000||b0< -10000000||b0>10000000 do return INVALID
 for i:=i64(0);i<n;i+=1 {x:=v[5+2*i];y:=v[6+2*i];if x< -10000000||x>10000000||y< -100000000||y>100000000 do return INVALID}
 alpha:=f64(rate)/1000000.0;w:=f64(m0)/1000000.0;b:=f64(b0)/1000000.0
 for epoch:=i64(0);epoch<epochs;epoch+=1 {for i:=i64(0);i<n;i+=1 {x:=f64(v[5+2*i])/1000000.0;y:=f64(v[6+2*i])/1000000.0;error:=w*x+b-y;w-=alpha*(error*x/f64(n));b-=alpha*(error/f64(n))}}
 return w
}
