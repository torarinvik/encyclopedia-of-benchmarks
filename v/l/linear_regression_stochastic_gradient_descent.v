const invalid_result = -1.0e300
@[export: 'linear_regression_stochastic_gradient_descent']
pub fn linear_regression_stochastic_gradient_descent(input &i64,length usize) f64 {
 if length<9||length>133{return invalid_result}
 unsafe {
  n:=input[0];epochs:=input[1];rate:=input[2];m0:=input[3];b0:=input[4]
  if n<2||n>64||length!=usize(5+2*n)||epochs<1||epochs>200||rate<1||rate>10000||m0< -10000000||m0>10000000||b0< -10000000||b0>10000000{return invalid_result}
  for i:=i64(0);i<n;i++{x:=input[5+2*i];y:=input[6+2*i];if x< -10000000||x>10000000||y< -100000000||y>100000000{return invalid_result}}
  alpha:=f64(rate)/1000000.0;mut w:=f64(m0)/1000000.0;mut b:=f64(b0)/1000000.0
  for _ in 0..int(epochs){for i:=i64(0);i<n;i++{x:=f64(input[5+2*i])/1000000.0;y:=f64(input[6+2*i])/1000000.0;error:=w*x+b-y;w-=alpha*(error*x/f64(n));b-=alpha*(error/f64(n))}}
  return w
 }
}
