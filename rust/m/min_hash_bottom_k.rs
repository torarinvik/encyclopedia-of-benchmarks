const MAX_INPUT: usize = 35;
unsafe fn put64(o: *mut u8, p: usize, x: i64) { let b=x as u64; for j in 0..8 { *o.add(p+j)=(b>>(8*j)) as u8; } }
#[no_mangle]
pub unsafe extern "C" fn min_hash_bottom_k(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
 if input.is_null()||length<4||length>MAX_INPUT{return -1;}let nr=*input;let kr=*input.add(1);if nr<1||nr>16||kr<1||kr>8||length!=2+2*nr as usize{return -1;}let n=nr as usize;let k=kr as usize;let mut ids=[0usize;16];let mut ranks=[0i64;16];let mut count=0usize;
 for i in 0..n {let id=*input.add(2+2*i);let rank=*input.add(3+2*i);if id<0||id>=16||rank<0||rank>1000{return -1;}for j in 0..i{if id==*input.add(2+2*j){return -1;}}let mut pos=0;while pos<count&&(ranks[pos]<rank||(ranks[pos]==rank&&ids[pos]<id as usize)){pos+=1;}if pos<k{let mut next=if count<k{count}else{k-1};while next>pos{ids[next]=ids[next-1];ranks[next]=ranks[next-1];next-=1;}ids[pos]=id as usize;ranks[pos]=rank;if count<k{count+=1;}}}
 let bytes=8*(1+2*count);if output.is_null()||capacity<bytes{return -2;}put64(output,0,count as i64);for i in 0..count{put64(output,8+16*i,ids[i] as i64);put64(output,16+16*i,ranks[i]);}bytes as i64
}
