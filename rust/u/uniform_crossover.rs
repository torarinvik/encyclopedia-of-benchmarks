fn put_i64_le(output:*mut u8,offset:usize,value:i64){unsafe{std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(),output.add(offset),8);}}
#[no_mangle]
pub unsafe extern "C" fn uniform_crossover(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4||length>193{return -1;}let n=*input;if n<1||n>64||length!=(1+3*n)as usize{return -1;}
 for i in 0..n as usize{let a=*input.add(1+i);if a!=0&&a!=1{return -1;}}
 for i in 0..(2*n)as usize{let gene=*input.add(1+n as usize+i);if !(-2147483648..=2147483647).contains(&gene){return -1;}}
 let count=n as usize;let bytes=16*count;if output.is_null()||capacity<bytes{return -2;}
 for i in 0..count{let a=*input.add(1+i);let p=*input.add(1+count+i);let q=*input.add(1+2*count+i);let(c1,c2)=if a==1{(p,q)}else{(q,p)};put_i64_le(output,i*8,c1);put_i64_le(output,(count+i)*8,c2);}bytes as i64
}
