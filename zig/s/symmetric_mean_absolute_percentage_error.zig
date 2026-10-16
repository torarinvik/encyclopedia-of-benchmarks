const INVALID:f64=-1.0e300;const SCALE:f64=1000000.0;
export fn symmetric_mean_absolute_percentage_error(values:[*]const i64,length:usize) f64{
    if(length<1)return INVALID;const n0=values[0];if(n0<1 or n0>64)return INVALID;const n:usize=@intCast(n0);if(length!=1+2*n)return INVALID;for(0..2*n)|i|{const x=values[1+i];if(x< -1000000 or x>1000000)return INVALID;}var total:f64=0;for(0..n)|i|{const t=@as(f64,@floatFromInt(values[1+i]))/SCALE;const p=@as(f64,@floatFromInt(values[1+n+i]))/SCALE;var d=(@abs(t)+@abs(p))/2.0;if(d==0.0)d=1e-15;total+=@abs(t-p)/d;}return total/@as(f64,@floatFromInt(n));
}
