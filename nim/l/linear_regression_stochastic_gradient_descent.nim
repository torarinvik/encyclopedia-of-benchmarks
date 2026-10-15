const InvalidResult = -1.0e300
proc linear_regression_stochastic_gradient_descent*(input:ptr UncheckedArray[int64],length:csize_t):float64 {.cdecl,exportc:"linear_regression_stochastic_gradient_descent".} =
  if input==nil or length<9 or length>133:return InvalidResult
  let n=input[0];let epochs=input[1];let rate=input[2];let m0=input[3];let b0=input[4]
  if n<2 or n>64 or length!=csize_t(5+2*n) or epochs<1 or epochs>200 or rate<1 or rate>10000 or m0< -10000000 or m0>10000000 or b0< -10000000 or b0>10000000:return InvalidResult
  for i in 0..<int(n):
    let x=input[5+2*i];let y=input[6+2*i]
    if x< -10000000 or x>10000000 or y< -100000000 or y>100000000:return InvalidResult
  let alpha=float64(rate)/1000000.0
  var w=float64(m0)/1000000.0;var b=float64(b0)/1000000.0
  for epoch in 0..<int(epochs):
    for i in 0..<int(n):
      let x=float64(input[5+2*i])/1000000.0;let y=float64(input[6+2*i])/1000000.0
      let error=w*x+b-y
      w-=alpha*(error*x/float64(n));b-=alpha*(error/float64(n))
  w
