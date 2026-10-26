// Clean-room exact bounded minimum weighted connected dominating set.
const N:usize=16;
fn put(out:*mut u8,at:usize,x:i64){unsafe{std::ptr::copy_nonoverlapping(x.to_le_bytes().as_ptr(),out.add(at),8)}}
#[no_mangle]
pub unsafe extern "C" fn weighted_connected_dominating_set(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{if v.is_null()||n<3||n>33||*v<1||*v>16{return -1}let count=*v as usize;if n!=1+2*count{return -1}let all=(1u64<<count)-1;let mut adj=[0u64;N];for i in 0..count{let mask=*v.add(1+i);let weight=*v.add(1+count+i);if mask<0||mask as u64>all||(mask as u64&(1u64<<i))!=0||!(1..=1000).contains(&weight){return -1}adj[i]=mask as u64}for i in 0..count{for j in 0..count{if (adj[i]>>j)&1!=(adj[j]>>i)&1{return -1}}}
 let mut best=-1i64;let mut best_mask=0u64;for mask in 1..=all{let mut dominated=mask;let mut cost=0i64;for i in 0..count{if mask>>i&1!=0{dominated|=adj[i];cost+=*v.add(1+count+i)}}if dominated!=all{continue}let mut seen=mask&mask.wrapping_neg();loop{let old=seen;for i in 0..count{if seen>>i&1!=0{seen|=adj[i]&mask}}if seen==old{break}}if seen!=mask{continue}if best<0||cost<best||(cost==best&&mask<best_mask){best=cost;best_mask=mask}}
 if out.is_null()||cap<16{return -2}put(out,0,best);put(out,8,best_mask as i64);16}
