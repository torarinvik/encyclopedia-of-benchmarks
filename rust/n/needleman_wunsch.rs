const INVALID:i64=i64::MIN;
#[no_mangle]
pub unsafe extern "C" fn needleman_wunsch(v:*const i64,n:usize)->i64{
 if v.is_null()||n<5||n>261{return INVALID;}let a=std::slice::from_raw_parts(v,n);let (m,l,ms,mm,g)=(a[0],a[1],a[2],a[3],a[4]);
 if !(0..=128).contains(&m)||!(0..=128).contains(&l)||!(0..=10).contains(&ms)||!(-10..=0).contains(&mm)||!(-10..=0).contains(&g)||n!=5+m as usize+l as usize{return INVALID;}
 if a[5..].iter().any(|&c|!(65..=90).contains(&c)){return INVALID;}let(mut dp)=[0i64;129];for j in 0..=l as usize{dp[j]=j as i64*g;}
 for i in 1..=m as usize{let mut diagonal=dp[0];dp[0]=i as i64*g;for j in 1..=l as usize{let old=dp[j];let score=if a[5+i-1]==a[5+m as usize+j-1]{ms}else{mm};dp[j]=(diagonal+score).max(old+g).max(dp[j-1]+g);diagonal=old;}}dp[l as usize]
}
