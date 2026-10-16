const SMALL:[&str;20]=["Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"];
const TENS:[&str;10]=["","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"];
const SCALE:[&str;5]=["","Thousand","Million","Billion","Trillion"];
fn add(s:&mut String,w:&str){if !s.is_empty(){s.push(' ')}s.push_str(w)}
fn chunk(s:&mut String,mut x:u32){if x>=100{add(s,SMALL[(x/100) as usize]);add(s,"Hundred");x%=100;}if x>=20{add(s,TENS[(x/10) as usize]);x%=10;}if x>0&&x<20{add(s,SMALL[x as usize]);}}
#[no_mangle]
pub unsafe extern "C" fn number_to_words(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<3||n>9{return -1}let a=std::slice::from_raw_parts(v,n);if !(-1..=1).contains(&a[0])||a[1]<0||a[1]>999_999_999_999_999||a[2]<0||a[2]>6||n!=a[2] as usize+3{return -1}
 let mut nz=a[1]!=0;for &x in &a[3..]{if !(0..=9).contains(&x){return -1}if x!=0{nz=true}}if(nz&&a[0]==0)||(!nz&&a[0]!=0){return -1}
 let mut s=String::new();if a[0]<0{add(&mut s,"Negative")}let mut whole=a[1] as u64;let mut g=[0u32;5];for x in &mut g{*x=(whole%1000) as u32;whole/=1000;}let mut any=false;for i in (0..5).rev(){if g[i]!=0{chunk(&mut s,g[i]);if i>0{add(&mut s,SCALE[i])}any=true}}if !any{add(&mut s,"Zero")}
 if a[3..].iter().any(|&x|x!=0){add(&mut s,"Point");for &x in &a[3..]{add(&mut s,SMALL[x as usize]);}}
 if s.len()>cap||(!s.is_empty()&&out.is_null()){return -2}std::ptr::copy_nonoverlapping(s.as_ptr(),out,s.len());s.len() as i64
}
