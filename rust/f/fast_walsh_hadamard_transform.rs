#[no_mangle]
pub unsafe extern "C" fn fast_walsh_hadamard_transform(v:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||len<2||len>130{return -1}let input=std::slice::from_raw_parts(v,len);let inv=input[0];let n=input[1];if !(0..=1).contains(&inv)||!(1..=128).contains(&n)||n&(n-1)!=0||len!=n as usize+2{return -1}let n=n as usize;
 let mut a=[0i64;128];for i in 0..n{if !(-10000..=10000).contains(&input[i+2]){return -1}a[i]=input[i+2];}
 let mut h=1;while h<n{let mut b=0;while b<n{for j in 0..h{let x=a[b+j];let y=a[b+j+h];a[b+j]=x+y;a[b+j+h]=x-y;}b+=2*h;}h*=2;}
 if inv==1{for x in &mut a[..n]{if *x%(n as i64)!=0{return -1}*x/=n as i64;}}
 if n*8>cap||out.is_null(){return -2}for i in 0..n{let bytes=a[i].to_le_bytes();std::ptr::copy_nonoverlapping(bytes.as_ptr(),out.add(i*8),8);}n as i64
}
