module huber_loss_math
const scale=i64(1_000_000)
const max_count=i64(64)
const max_parsed_count=i64(65)
const max_sample=i64(1_000_000_000)
const max_delta=i64(1_000_000_000)
const max_input_length=usize(133)
const invalid_result=-1.0e300
@[export:'huber_loss_math']
pub fn huber_loss_math(v &i64,n usize) f64{
 if unsafe{v==nil}||n<3||n>max_input_length{return invalid_result}
 d,ac,pc:=unsafe{v[0]},unsafe{v[1]},unsafe{v[2]}
 if d<0||d>max_delta||ac<0||ac>max_parsed_count||pc<0||pc>max_parsed_count||n!=usize(3+ac+pc)||ac>max_count||pc>max_count{return invalid_result}
 a,p:=int(ac),int(pc)
 for i in 0..a+p{x:=unsafe{v[3+i]};if x< -max_sample||x>max_sample{return invalid_result}}
 delta:=f64(d)/f64(scale);mut total:=0.0;pairs:=a;if p<a{pairs=p}
 for i in 0..pairs{diff:=f64(unsafe{v[3+i]})/f64(scale)-f64(unsafe{v[3+a+i]})/f64(scale);mut residual:=diff;if residual<0.0{residual=-residual};if residual<=delta{total+=0.5*(diff*diff)}else{total+=delta*residual-0.5*delta}}
 return total
}
