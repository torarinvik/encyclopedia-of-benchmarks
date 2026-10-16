package huber_loss_math
import "core:c"
SCALE::i64=1_000_000;MAX_COUNT::i64=64;MAX_PARSED_COUNT::i64=65;MAX_SAMPLE::i64=1_000_000_000;MAX_DELTA::i64=1_000_000_000;MAX_INPUT_LENGTH::c.size_t=133;INVALID_RESULT::f64(-1.0e300)
@(export)
huber_loss_math::proc "c"(v:[^]i64,n:c.size_t)->f64{
 if v==nil||n<3||n>MAX_INPUT_LENGTH do return INVALID_RESULT
 d,ac,pc:=v[0],v[1],v[2]
 if d<0||d>MAX_DELTA||ac<0||ac>MAX_PARSED_COUNT||pc<0||pc>MAX_PARSED_COUNT||n!=c.size_t(3+ac+pc)||ac>MAX_COUNT||pc>MAX_COUNT do return INVALID_RESULT
 a,p:=int(ac),int(pc)
 for i:=0;i<a+p;i+=1{if v[3+i]<-MAX_SAMPLE||v[3+i]>MAX_SAMPLE do return INVALID_RESULT}
 delta:=f64(d)/f64(SCALE);total:=f64(0.0);pairs:=a;if p<a{pairs=p}
 for i:=0;i<pairs;i+=1{diff:=f64(v[3+i])/f64(SCALE)-f64(v[3+a+i])/f64(SCALE);residual:=diff;if residual<0.0{residual=-residual};if residual<=delta{total+=0.5*(diff*diff)}else{total+=delta*residual-0.5*delta}}
 return total
}
