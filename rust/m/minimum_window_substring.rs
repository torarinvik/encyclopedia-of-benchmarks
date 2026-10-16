const MAX_TEXT:usize=128;
#[no_mangle]
pub unsafe extern "C" fn minimum_window_substring(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<3||n>258{return -1;}let a=std::slice::from_raw_parts(v,n);if a[0]<0||a[0]>MAX_TEXT as i64{return -1;}let s=a[0] as usize;if n<s+2{return -1;}let mm=a[s+1];if mm<1||mm>MAX_TEXT as i64{return -1;}let m=mm as usize;if n!=s+m+2{return -1;}
 let mut need=[0i32;128];for &c in &a[1..s+1]{if !(0..=127).contains(&c){return -1;}}for &c in &a[s+2..]{if !(0..=127).contains(&c){return -1;}need[c as usize]+=1;}
 let(mut left,mut best,mut start,mut missing)=(0usize,s+1,0usize,m as i32);for right in 0..s{let c=a[right+1] as usize;if need[c]>0{missing-=1;}need[c]-=1;while missing==0{let len=right-left+1;if len<best{best=len;start=left;}let x=a[left+1] as usize;need[x]+=1;left+=1;if need[x]>0{missing+=1;}}}
 if best==s+1{return 0;}if best>cap||(best>0&&out.is_null()){return -2;}for i in 0..best{*out.add(i)=a[start+1+i] as u8;}best as i64
}
