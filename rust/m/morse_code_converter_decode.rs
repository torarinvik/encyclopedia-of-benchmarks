const MAX_INPUT_LENGTH: usize = 512;
const MAX_OUTPUT_BYTES: usize = 512;
const MORSE: [&[u8]; 26] = [b".-", b"-...", b"-.-.", b"-..", b".", b"..-.", b"--.", b"....", b"..", b".---", b"-.-", b".-..", b"--", b"-.", b"---", b".--.", b"--.-", b".-.", b"...", b"-", b"..-", b"...-", b".--", b"-..-", b"-.--", b"--.."];
fn separator(text:&[i64],pos:usize,end:usize)->bool{pos+2<end&&text[pos]==32&&text[pos+1]==124&&text[pos+2]==32}
fn decode_token(text:&[i64],start:usize,end:usize)->u8{
 for (letter,code) in MORSE.iter().enumerate(){if end-start==code.len()&&text[start..end].iter().zip(*code).all(|(&a,&b)|a==b as i64){return b'A'+letter as u8;}} b'?'
}
fn append_word(text:&[i64],start:usize,finish:usize,out:&mut [u8;MAX_OUTPUT_BYTES],written:&mut usize){
 if start==finish{out[*written]=b'?';*written+=1;return;} let mut end=finish;while end>start&&text[end-1]==32{end-=1;}if start==end{return;}let mut token=start;for pos in start..=end{if pos==end||text[pos]==32{out[*written]=decode_token(text,token,pos);*written+=1;token=pos+1;}}
}
fn decode(text:&[i64],out:&mut [u8;MAX_OUTPUT_BYTES])->usize{
 if text.is_empty(){out[0]=b'?';return 1;}let mut end=text.len();while end>=3&&separator(text,end-3,end){end-=3;}if end==0{return 0;}let mut written=0;let mut start=0;let mut pos=0;while pos+2<end{if separator(text,pos,end){append_word(text,start,pos,out,&mut written);out[written]=b' ';written+=1;pos+=3;start=pos;}else{pos+=1;}}append_word(text,start,end,out,&mut written);written
}
#[no_mangle]
pub unsafe extern "C" fn morse_code_converter_decode(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if (input.is_null()&&length>0)||length>MAX_INPUT_LENGTH{return -1;}let text: &[i64]=if length==0{&[]}else{std::slice::from_raw_parts(input,length)};if text.iter().any(|&x|!(0..=127).contains(&x)){return -1;}let mut scratch=[0u8;MAX_OUTPUT_BYTES];let written=decode(text,&mut scratch);if output.is_null()||capacity<written{return -2;}if written>0{std::ptr::copy_nonoverlapping(scratch.as_ptr(),output,written);}written as i64
}
