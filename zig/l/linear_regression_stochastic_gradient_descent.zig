const INVALID:f64=-1.0e300;
/// Return the final slope after ordered per-row stochastic updates.
export fn linear_regression_stochastic_gradient_descent(input:[*]const i64,length:usize)f64{
 if(length<9 or length>133)return INVALID;const v=input[0..length];const n=v[0];const epochs=v[1];const rate=v[2];const m0=v[3];const b0=v[4];
 if(n<2 or n>64 or length!=5+2*@as(usize,@intCast(n)) or epochs<1 or epochs>200 or rate<1 or rate>10000 or m0< -10000000 or m0>10000000 or b0< -10000000 or b0>10000000)return INVALID;
 for(0..@intCast(n))|i|{const x=v[5+2*i];const y=v[6+2*i];if(x< -10000000 or x>10000000 or y< -100000000 or y>100000000)return INVALID;}
 const alpha=@as(f64,@floatFromInt(rate))/1000000.0;var w=@as(f64,@floatFromInt(m0))/1000000.0;var b=@as(f64,@floatFromInt(b0))/1000000.0;
 for(0..@intCast(epochs)) |_| {for(0..@intCast(n))|i|{const x=@as(f64,@floatFromInt(v[5+2*i]))/1000000.0;const y=@as(f64,@floatFromInt(v[6+2*i]))/1000000.0;const error=w*x+b-y;w-=alpha*(error*x/@as(f64,@floatFromInt(n)));b-=alpha*(error/@as(f64,@floatFromInt(n)));}}
 return w;
}
