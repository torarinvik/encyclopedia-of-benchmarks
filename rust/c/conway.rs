const MAX_TEXT_LENGTH: usize=128;
fn decimal_digits(mut value:usize)->usize{let mut n=1;while value>=10{value/=10;n+=1;}n}
/// Generate the next look-and-say string from bounded ASCII input.
#[no_mangle]
pub extern "C" fn conway(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>MAX_TEXT_LENGTH+1{return -1;}
 let values=unsafe{std::slice::from_raw_parts(input,length)};let n=values[0];if n<1||n>MAX_TEXT_LENGTH as i64||length!=n as usize+1{return -1;}
 if values[1..].iter().any(|&ch| !(0..=127).contains(&ch)){return -1;}
 let mut needed=0usize;let mut i=0;while i<n as usize{let mut j=i+1;while j<n as usize&&(values[j]==values[j+1]||values[j]==10||values[j]==13){j+=1;}needed+=decimal_digits(j-i)+1;i=j;}
 if output.is_null()||capacity<needed{return -2;}let out=unsafe{std::slice::from_raw_parts_mut(output,capacity)};let mut pos=0usize;i=0;
 while i<n as usize{let mut j=i+1;while j<n as usize&&(values[j]==values[j+1]||values[j]==10||values[j]==13){j+=1;}let mut run=j-i;let start=pos;loop{out[pos]=b'0'+(run%10) as u8;pos+=1;run/=10;if run==0{break;}}out[start..pos].reverse();out[pos]=values[i+1] as u8;pos+=1;i=j;}
 pos as i64
}
