const MAX_LENGTH: usize = 1024;
fn ascii_space(c:i64)->bool{matches!(c,9|10|11|12|13|32)}
#[no_mangle]
pub unsafe extern "C" fn validate_email(v:*const i64,n:usize)->i64{
    if v.is_null()||n<2||n>MAX_LENGTH+1{return -1;}let v=std::slice::from_raw_parts(v,n);
    if !(1..=MAX_LENGTH as i64).contains(&v[0])||v[0] as usize+1!=n{return -1;}
    let mut end=v[0] as usize;for &c in &v[1..=end]{if !(0..=127).contains(&c){return -1;}}
    let mut at=end;for i in 0..end{let c=v[i+1];if ascii_space(c){return 0;}if c==64{if at!=end{return 0;}at=i;}}
    if at==0||at>=end-1{return 0;}for i in at+2..end-1{if v[i+1]==46{return 1;}}0
}
