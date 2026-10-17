const MAX_TEXT: usize = 256;
const MAX_INPUT: usize = MAX_TEXT + 2;
#[no_mangle]
pub unsafe extern "C" fn split(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>MAX_INPUT+1{return -1;}let values=core::slice::from_raw_parts(input,length);
 if !(0..=MAX_TEXT as i64).contains(&values[0])||!(0..=127).contains(&values[1]){return -1;}let n=values[0] as usize;if length!=n+2{return -1;}
 if values[2..].iter().any(|&x|!(0..=127).contains(&x)){return -1;}if n>0&&values[n+1]==values[1]{return -1;}
 let separators=values[2..].iter().filter(|&&x|x==values[1]).count();if n>0&&separators==0{return -1;}let count=separators+1;let required=2+2*count+n-separators;
 if output.is_null()||capacity<required{return -2;}let result=core::slice::from_raw_parts_mut(output,capacity);result[0]=count as u8;result[1]=(count>>8)as u8;let mut pos=2;let mut start=0;
 for i in 0..=n{if i==n||values[i+2]==values[1]{let field=i-start;result[pos]=field as u8;result[pos+1]=(field>>8)as u8;pos+=2;for j in start..i{result[pos]=values[j+2] as u8;pos+=1;}start=i+1;}}required as i64
}
