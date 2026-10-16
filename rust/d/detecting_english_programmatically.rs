use std::slice;

#[no_mangle]
pub unsafe extern "C" fn detecting_english_programmatically(a: *const i64, n: usize) -> i64 {
    if a.is_null() || n < 1 || n > 172 { return -1; }
    let x = slice::from_raw_parts(a, n); let mut p=0usize;
    let count=x[p];p+=1;if !(0..=8).contains(&count){return -1;}
    let mut dict:Vec<Vec<i64>>=Vec::new();
    for _ in 0..count { if p>=n{return -1;} let l=x[p];p+=1;if !(1..=12).contains(&l)||p+l as usize>n{return -1;}
        let w=x[p..p+l as usize].to_vec();if w.iter().any(|&c|!(65..=90).contains(&c))||dict.last().map_or(false,|prev|prev>=&w){return -1;}dict.push(w);p+=l as usize; }
    if p>=n{return -1;}let m=x[p];p+=1;if !(1..=64).contains(&m)||p+m as usize+2!=n{return -1;}
    let msg=&x[p..p+m as usize];p+=m as usize;if msg.iter().any(|&c|!(0..=127).contains(&c)){return -1;}
    let wp=x[p];let lp=x[p+1];if !(0..=100).contains(&wp)||!(0..=100).contains(&lp){return -1;}
    let mut retained=0i64;let mut tokens=0i64;let mut hits=0i64;let mut i=0usize;let mut tok:Vec<i64>=Vec::new();
    while i<=msg.len(){let c=if i<msg.len(){msg[i]}else{32};let letter=(65..=90).contains(&c)||(97..=122).contains(&c);let ws=c==9||c==10||c==32;if i<msg.len()&&(letter||ws){retained+=1;}
        if letter{tok.push(if c>=97{c-32}else{c});i+=1;continue;}if !ws{i+=1;continue;}if tok.is_empty(){i+=1;continue;}
        tokens+=1;if dict.iter().any(|w|w==&tok){hits+=1;}tok.clear();i+=1;
    }
    if tokens==0{return -1;}
    i64::from(hits*100>=wp*tokens&&retained*100>=lp*m)
}
