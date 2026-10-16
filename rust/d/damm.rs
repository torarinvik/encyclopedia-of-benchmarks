const MAX_DIGITS: usize=256;
const TABLE: [i8;100]=[0, 3, 1, 7, 5, 9, 8, 6, 4, 2, 7, 0, 9, 2, 1, 5, 4, 8, 6, 3, 4, 2, 0, 6, 8, 7, 1, 3, 5, 9, 1, 7, 5, 0, 9, 8, 3, 4, 2, 6, 6, 1, 2, 3, 0, 4, 5, 9, 7, 8, 3, 6, 7, 4, 2, 0, 9, 5, 8, 1, 5, 8, 6, 9, 7, 2, 0, 1, 3, 4, 8, 9, 4, 5, 3, 6, 2, 0, 1, 7, 9, 4, 3, 8, 6, 1, 7, 2, 0, 5, 2, 5, 8, 1, 4, 3, 6, 7, 9, 0];
/// Validate a digit sequence or compute its appended Damm check digit.
#[no_mangle]
pub extern "C" fn damm(input:*const i64,length:usize)->i64 {
 if input.is_null()||length<3||length>MAX_DIGITS+2{return -1;}
 let values=unsafe{std::slice::from_raw_parts(input,length)};let mode=values[0];let n=values[1];
 if (mode!=0&&mode!=1)||n<1||n>MAX_DIGITS as i64||length!=n as usize+2{return -1;}
 let mut state=0usize;for &d in &values[2..]{if d<0||d>9{return -1;}state=TABLE[state*10+d as usize] as usize;}
 if mode==0{if state==0{1}else{0}}else{state as i64}
}
