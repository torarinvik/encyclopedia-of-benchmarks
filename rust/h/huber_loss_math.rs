const SCALE:i64=1_000_000; const MAX_COUNT:i64=64; const MAX_PARSED_COUNT:i64=65; const MAX_SAMPLE:i64=1_000_000_000; const MAX_DELTA:i64=1_000_000_000; const MAX_INPUT_LENGTH:usize=133; const INVALID_RESULT:f64=-1.0e300;
#[no_mangle] pub unsafe extern "C" fn huber_loss_math(v:*const i64,n:usize)->f64{
 if v.is_null()||n<3||n>MAX_INPUT_LENGTH{return INVALID_RESULT;}
 let d=*v;let ac=*v.add(1);let pc=*v.add(2);
 if d<0||d>MAX_DELTA||ac<0||ac>MAX_PARSED_COUNT||pc<0||pc>MAX_PARSED_COUNT||n!=(3+ac+pc)as usize||ac>MAX_COUNT||pc>MAX_COUNT{return INVALID_RESULT;}
 let a=ac as usize;let p=pc as usize;
 for i in 0..a+p{let x=*v.add(3+i);if x< -MAX_SAMPLE||x>MAX_SAMPLE{return INVALID_RESULT;}}
 let delta=d as f64/SCALE as f64;let mut total=0.0;let pairs=a.min(p);
 for i in 0..pairs{let diff=*v.add(3+i)as f64/SCALE as f64-*v.add(3+a+i)as f64/SCALE as f64;let residual=diff.abs();if residual<=delta{total+=0.5*diff.powf(2.0);}else{total+=delta*residual-0.5*delta;}}
 total
}
