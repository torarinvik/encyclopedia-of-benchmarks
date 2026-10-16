module huber_loss_math;
const long SCALE=1000000;const long MAX_COUNT=64;const long MAX_PARSED_COUNT=65;const long MAX_SAMPLE=1000000000;const long MAX_DELTA=1000000000;const usz MAX_INPUT_LENGTH=133;const double INVALID_RESULT=-1.0e300;
fn double huber_loss_math_impl(long* v,usz n){
 if(v==null||n<3||n>MAX_INPUT_LENGTH)return INVALID_RESULT;
 long d=v[0],ac=v[1],pc=v[2];
 if(d<0||d>MAX_DELTA||ac<0||ac>MAX_PARSED_COUNT||pc<0||pc>MAX_PARSED_COUNT||n!=(usz)(3+ac+pc)||ac>MAX_COUNT||pc>MAX_COUNT)return INVALID_RESULT;
 usz a=(usz)ac,p=(usz)pc;
 for(usz i=0;i<a+p;i++)if(v[3+i]<-MAX_SAMPLE||v[3+i]>MAX_SAMPLE)return INVALID_RESULT;
 double delta=(double)d/(double)SCALE,total=0.0;usz pairs=a<p?a:p;
 for(usz i=0;i<pairs;i++){double diff=(double)v[3+i]/(double)SCALE-(double)v[3+a+i]/(double)SCALE;double residual=diff<0.0?-diff:diff;if(residual<=delta)total+=0.5*(diff*diff);else total+=delta*residual-0.5*delta;}
 return total;
}
fn double huber_loss(long* v,usz n) @export("huber_loss_math"){return huber_loss_math_impl(v,n);}
