#[no_mangle]
pub unsafe extern "C" fn nysiis_encoder(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 2 || n > 65 { return -1; }
    let a=std::slice::from_raw_parts(v,n); if !(1..=64).contains(&a[0]) || n != a[0] as usize+1 { return -1; }
    let mut s=String::new();
    for &x in &a[1..] { if !(0..=127).contains(&x) { return -1; } let mut c=x as u8 as char; if c.is_ascii_lowercase(){c=c.to_ascii_uppercase()} if !c.is_ascii_uppercase(){return -1} s.push(c); }
    if s.is_empty(){return -1}
    fn replace(s:&mut String,i:usize,from:&str,to:&str){s.replace_range(i..i+from.len(),to)}
    let pref=[("MAC","MCC"),("KN","NN"),("K","C"),("PH","FF"),("PF","FF"),("SCH","SSS")];
    for (f,t) in pref {if s.starts_with(f){replace(&mut s,0,f,t);break}}
    let suff=[("EE","Y"),("IE","Y"),("DT","D"),("RT","D"),("NT","D"),("ND","D")];
    for (f,t) in suff {if s.ends_with(f){let i=s.len()-f.len();replace(&mut s,i,f,t);break}}
    let rules=[("EV","AF"),("E","A"),("I","A"),("O","A"),("U","A"),("Q","G"),("Z","S"),("M","N"),("KN","NN"),("K","C"),("SCH","SSS"),("PH","FF")];
    let mut i=1;while i<s.len(){let mut done=false;for (f,t) in rules{if s[i..].starts_with(f){replace(&mut s,i,f,t);done=true;break}}if !done{let b=s.as_bytes();let c=b[i] as char;let prev=b[i-1] as char;if (c=='H'&&(!"AEIOU".contains(prev)||i+1<s.len()&&!"AEIOU".contains(b[i+1] as char)))||(c=='W'&&"AEIOU".contains(prev)){let old=s[i..i+1].to_string();let new=prev.to_string();replace(&mut s,i,&old,&new);}}i+=1;}
    let mut d=String::new();for c in s.chars(){if d.chars().last()!=Some(c){d.push(c)}}s=d;
    if s.ends_with('S'){s.pop();}else if s.ends_with("AY"){let i=s.len()-2;s.replace_range(i..,"Y");}else if s.ends_with('A'){s.pop();}
    if s.len()>cap||(s.len()>0&&out.is_null()){return -2} if !s.is_empty(){std::ptr::copy_nonoverlapping(s.as_ptr(),out,s.len())};s.len() as i64
}
