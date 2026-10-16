const SCALE:i64=1_000_000;const MAX_COUNT:i64=64;const MAX_PARSED_COUNT:i64=65;const MAX_SAMPLE:i64=1_000_000_000;const MAX_DELTA:i64=1_000_000_000;const MAX_INPUT_LENGTH:usize=133;const INVALID_RESULT:f64=-1.0e300;
export fn huber_loss_math(v:[*c]const i64,n:usize)f64{
 if(v==null or n<3 or n>MAX_INPUT_LENGTH)return INVALID_RESULT;
 const d=v[0];const ac=v[1];const pc=v[2];
 if(d<0 or d>MAX_DELTA or ac<0 or ac>MAX_PARSED_COUNT or pc<0 or pc>MAX_PARSED_COUNT or n!=@as(usize,@intCast(3+ac+pc)) or ac>MAX_COUNT or pc>MAX_COUNT)return INVALID_RESULT;
 const a:usize=@intCast(ac);const p:usize=@intCast(pc);
 for(0..a+p)|i|{if(v[3+i]<-MAX_SAMPLE or v[3+i]>MAX_SAMPLE)return INVALID_RESULT;}
 const delta=@as(f64,@floatFromInt(d))/@as(f64,@floatFromInt(SCALE));var total:f64=0.0;const pairs=@min(a,p);
 for(0..pairs)|i|{const diff=@as(f64,@floatFromInt(v[3+i]))/@as(f64,@floatFromInt(SCALE))-@as(f64,@floatFromInt(v[3+a+i]))/@as(f64,@floatFromInt(SCALE));const residual=@abs(diff);if(residual<=delta)total+=0.5*diff*diff else total+=delta*residual-0.5*delta;}
 return total;
}
