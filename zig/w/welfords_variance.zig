const MAX_LENGTH:usize=64;const MAX_ABS_VALUE:i64=1_000_000;const INVALID_RESULT:f64=-1.0e300;
export fn welfords_variance(values:[*c]const i64,length:usize) f64 {
 if(values==null or length<2 or length>MAX_LENGTH)return INVALID_RESULT;var mean:f64=0;var m2:f64=0;for(0..length)|i|{const x=values[i];if(x< -MAX_ABS_VALUE or x>MAX_ABS_VALUE)return INVALID_RESULT;const delta=@as(f64,@floatFromInt(x))-mean;mean+=delta/@as(f64,@floatFromInt(i+1));m2+=delta*(@as(f64,@floatFromInt(x))-mean);}return m2/@as(f64,@floatFromInt(length-1));
}
