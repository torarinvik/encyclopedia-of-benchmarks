#[no_mangle]
pub extern "C" fn x932_padding(values:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if values.is_null()||length<1||length>257{return -1;} let input=unsafe{std::slice::from_raw_parts(values,length)}; if !(1..=64).contains(&input[0])||input[1..].iter().any(|&v|!(0..=255).contains(&v)){return -1;} let block=input[0] as usize;let n=length-1;let pad=block-(n%block);let total=n+pad;if total>capacity||output.is_null(){return -2;} let out=unsafe{std::slice::from_raw_parts_mut(output,total)};for i in 0..n{out[i]=input[i+1] as u8;}for i in n..total-1{out[i]=0;}out[total-1]=pad as u8;total as i64
}
