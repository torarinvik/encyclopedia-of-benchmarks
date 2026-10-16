module ewma_change_detector
@[export: 'ewma_change_detector']
pub fn ewma_change_detector(v &i64,n usize) i64 {
 if unsafe{v==nil}||n<1||n>16{return -1}
 count:=unsafe{v[0]};if count<0||count>15||n!=usize(count+1){return -1}
 mut exponent:=i64(0);mut numerator:=i64(0);mut packed:=i64(0)
 for i in 0..int(count){sample:=unsafe{v[i+1]};if sample < -8||sample>8{return -1};exponent++;numerator+=sample*(i64(1)<<(exponent-1));mut signal:=i64(0);if 3*numerator*numerator>((i64(1)<<(2*exponent))-1){signal=if numerator>0 {i64(1)} else {i64(2)};exponent=0;numerator=0};packed=packed*4+signal}
 return packed
}
