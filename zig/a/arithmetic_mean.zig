const MAX_LENGTH:usize=64; const BOUND:i64=1_000_000; const INVALID:f64=-1.0e300;
export fn arithmetic_mean(values:[*]const i64,length:usize)f64 {
 if(length==0 or length>MAX_LENGTH)return INVALID; var total:i64=0;
 for(0..length)|i|{if(values[i]<-BOUND or values[i]>BOUND)return INVALID; total+=values[i];}
 return @as(f64,@floatFromInt(total))/@as(f64,@floatFromInt(length));
}
