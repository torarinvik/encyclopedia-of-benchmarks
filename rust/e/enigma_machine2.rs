const ROTORS:[&[u8;26];3]=[b"EGZWVONAHDCLFQMSIPJBYUKXTR",b"FOBHMDKEXQNRAULPGSJVTYICZW",b"ZJXESIUQLHAVRMDOYGTNFWPBKC"];
fn md(x:i32)->usize{x.rem_euclid(26) as usize}
#[no_mangle] pub unsafe extern "C" fn enigma_machine2(a:*const i64,len:usize)->i64{
 if a.is_null()||len<4||len>16{return -1}let v=std::slice::from_raw_parts(a,len);let n=v[0];if n<0||n>12||len!=4+n as usize{return -1}let mut p=[0i32;3];for j in 0..3{if v[1+j]<1||v[1+j]>26{return -1}p[j]=v[1+j] as i32-1;}if v[4..].iter().any(|&x|x<0||x>25){return -1}
 let mut out=0i64;for &letter in &v[4..]{let mut x=letter as i32;for r in 0..3{x=(ROTORS[r][md(x+p[r])]-b'A') as i32;}x=md(x+13) as i32;for r in (0..3).rev(){let z=ROTORS[r].iter().position(|&c|(c-b'A') as i32==x).unwrap() as i32;x=md(z-p[r]) as i32;}out=out*26+x as i64;p[0]+=1;if p[0]==26{p[0]=0;p[1]+=1;if p[1]==26{p[1]=0;p[2]=(p[2]+1)%26;}}}out
}
