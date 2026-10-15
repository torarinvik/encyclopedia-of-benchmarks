/// Emit the median after each insertion into a fixed-width trailing window.
fn put(out:&mut [u8],at:usize,value:f64){out[at..at+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn windowed_median(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3{return -1}let x=std::slice::from_raw_parts(input,length);let w=x[0];let n=x[1];if !(1..=64).contains(&w)||!(1..=128).contains(&n)||length!=n as usize+2{return -1}
 let values=&x[2..];if values.iter().any(|v|!(-1_000_000..=1_000_000).contains(v)){return -1}let n=n as usize;let w=w as usize;if capacity<n*8||output.is_null(){return -2}
 let out=std::slice::from_raw_parts_mut(output,n*8);let mut sorted=[0i64;64];let mut active=0usize;
 for i in 0..n{if i>=w{let old=values[i-w];let mut p=0;while p<active&&sorted[p]!=old{p+=1}if p==active{return -1}for j in p+1..active{sorted[j-1]=sorted[j]}active-=1;}
  let value=values[i];let mut p=0;while p<active&&sorted[p]<value{p+=1}for j in (p..active).rev(){sorted[j+1]=sorted[j]}sorted[p]=value;active+=1;
  let median:f32=if active%2==1{sorted[active/2] as f32}else{0.5f32*sorted[active/2-1] as f32+0.5f32*sorted[active/2] as f32};put(out,i*8,median as f64);}
 (n*8)as i64
}
