/// Return page-reference hit/eviction events and final MRU-to-LRU state.
#[no_mangle]
pub unsafe extern "C" fn lru_page_reference(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2{return -1}let x=std::slice::from_raw_parts(input,length);let c=x[0];let n=x[1];if !(1..=64).contains(&c)||c&(c-1)!=0||!(0..=256).contains(&n)||length!=n as usize+2{return -1}
 let c=c as usize;let n=n as usize;if x[2..].iter().any(|p|!(0..=1_000_000).contains(p)){return -1}
 let mut cache=[0i64;64];let mut events=[0i64;512];let mut used=0usize;
 for i in 0..n{let page=x[2+i];let mut evicted=-1;let mut p=0;while p<used&&cache[p]!=page{p+=1}if p<used{for j in (1..=p).rev(){cache[j]=cache[j-1]}cache[0]=page;events[2*i]=1;}else{if used==c{evicted=cache[used-1];used-=1;}for j in (1..=used).rev(){cache[j]=cache[j-1]}cache[0]=page;used+=1;events[2*i]=0;}events[2*i+1]=evicted;}
 let words=2*n+2+used;if output.is_null()||capacity<words*8{return -2}let out=std::slice::from_raw_parts_mut(output,words*8);let mut result=[0i64;578];let mut k=0;result[k]=n as i64;k+=1;for v in &events[..2*n]{result[k]=*v;k+=1}result[k]=used as i64;k+=1;for v in &cache[..used]{result[k]=*v;k+=1}for i in 0..k{out[i*8..i*8+8].copy_from_slice(&result[i].to_le_bytes())} (words*8) as i64
}
