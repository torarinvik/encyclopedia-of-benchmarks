const MAX_N:usize=32;const MAX_INPUT:usize=35;
unsafe fn put64(o:*mut u8,p:usize,x:i64){let b=x as u64;for j in 0..8{*o.add(p+j)=(b>>(8*j)) as u8;}}
#[no_mangle] pub unsafe extern "C" fn max_average_length_bounded_segment(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4||length>MAX_INPUT{return -1}let n64=*input;let l64=*input.add(1);let u64=*input.add(2);
 if n64<1||n64>MAX_N as i64||l64<1||u64<l64||u64>n64||length!=3+n64 as usize{return -1}let n=n64 as usize;let lower=l64 as usize;let upper=u64 as usize;
 for i in 0..n{let x=*input.add(3+i);if x< -10000||x>10000{return -1}}if output.is_null()||capacity<32{return -2}
 let(mut bs,mut bl,mut bstart,mut bend,mut have)=(0i64,1usize,0usize,0usize,false);
 for start in 0..n{let mut sum=0i64;let limit=std::cmp::min(n,start+upper);for end in (start+1)..=limit{sum+=*input.add(3+end-1);let size=end-start;if size<lower{continue}let left=sum*bl as i64;let right=bs*size as i64;
  let tie=size<bl||(size==bl&&(start<bstart||(start==bstart&&end<bend)));
  if !have||left>right||(left==right&&tie){bs=sum;bl=size;bstart=start;bend=end;have=true}
 }}put64(output,0,bs);put64(output,8,bl as i64);put64(output,16,bstart as i64);put64(output,24,bend as i64);32
}
