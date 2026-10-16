const MAX_TERM: usize = 128;
const MAX_TEXT: usize = 4096;
const MAX_PACKED: usize = 4227;
const MAX_COUNT: i64 = 1_000_000;

fn punct(c: u8) -> bool { (33..=47).contains(&c) || (58..=64).contains(&c) || (91..=96).contains(&c) || (123..=126).contains(&c) }
fn lower_ascii(c: u8) -> u8 { if c.is_ascii_uppercase() { c + 32 } else { c } }
fn put32(out: &mut [u8], pos: &mut usize, value: u32) { out[*pos..*pos + 4].copy_from_slice(&value.to_le_bytes()); *pos += 4; }
fn put64(out: &mut [u8], pos: &mut usize, value: i64) { out[*pos..*pos + 8].copy_from_slice(&value.to_le_bytes()); *pos += 8; }
fn milli(x: f64) -> i64 {
    let y = x * 1000.0;
    let lo = y.floor();
    let frac = y - lo;
    if frac < 0.5 { return lo as i64; }
    if frac > 0.5 { return (lo + 1.0) as i64; }
    let k = lo as i64;
    if k % 2 == 0 { k } else { k + 1 }
}

#[no_mangle]
pub unsafe extern "C" fn word_frequency_functions(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PACKED { return -1; }
    let v = std::slice::from_raw_parts(input, length);
    let op = v[0];
    let mut kind = 0_i64;
    let mut a = 0_i64;
    let mut b = 0_i64;
    let mut out_len = 12_usize;
    if op == 0 || op == 1 {
        if length < 3 || v[1] < 0 || v[1] > MAX_TERM as i64 { return -1; }
        let tn = v[1] as usize;
        let ti = 2 + tn;
        if length < ti + 1 || v[ti] < 0 || v[ti] > MAX_TEXT as i64 { return -1; }
        let dn = v[ti] as usize;
        let di = ti + 1;
        if length != di + dn { return -1; }
        let mut term = [0_u8; MAX_TERM];
        let mut text = [0_u8; MAX_TEXT];
        let mut clean = [0_u8; MAX_TEXT];
        for i in 0..tn { let x=v[2+i]; if !(0..=127).contains(&x) { return -1; } term[i]=lower_ascii(x as u8); }
        for i in 0..dn { let x=v[di+i]; if !(0..=127).contains(&x) { return -1; } text[i]=x as u8; }
        let mut cn = 0;
        for &ch in &text[..dn] { if !punct(ch) && (op != 0 || ch != 10) { clean[cn]=if op==1 {lower_ascii(ch)} else {ch}; cn+=1; } }
        if op == 0 {
            let mut start=0;
            for i in 0..=cn { if i==cn || clean[i]==32 { let n=i-start; let mut same=n==tn; for j in 0..n { if same && lower_ascii(clean[start+j])!=term[j] {same=false;} } if same {a+=1;} start=i+1; } }
        } else {
            kind=1;out_len=20;let mut start=0;
            for i in 0..=cn { if i==cn || clean[i]==10 { let n=i-start;let mut found=tn==0;let mut j=0;while !found&&j+tn<=n {let mut k=0;while k<tn&&clean[start+j+k]==term[k]{k+=1;}if k==tn{found=true;}j+=1;}if found{a+=1;}b+=1;start=i+1;} }
        }
    } else if op == 2 {
        if length!=4{return -1;}let df=v[1];let n=v[2];let smooth=v[3];
        if df<0||df>MAX_COUNT||n<0||n>MAX_COUNT||(smooth!=0&&smooth!=1){return -1;}
        if smooth==1&&n==0{kind=4;out_len=4;}else if smooth==0&&df==0{kind=3;out_len=4;}else if smooth==0&&n==0{kind=4;out_len=4;}else{let value=if smooth==1{1.0+(n as f64/(1+df) as f64).log10()}else{(n as f64/df as f64).log10()};kind=2;a=milli(value);}
    } else if op == 3 {
        if length!=3||v[1]<0||v[1]>MAX_COUNT||v[2]<-MAX_COUNT||v[2]>MAX_COUNT{return -1;}
        kind=2;a=v[1]*v[2];
    } else { return -1; }
    if output.is_null()||capacity<out_len{return -2;}
    let out=std::slice::from_raw_parts_mut(output,out_len);let mut pos=0;put32(out,&mut pos,kind as u32);
    if kind==0||kind==2{put64(out,&mut pos,a);}else if kind==1{put64(out,&mut pos,a);put64(out,&mut pos,b);}
    pos as i64
}
