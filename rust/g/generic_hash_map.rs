const MAX: usize = 64;
fn hash_value(mut h: u64, value: i64) -> u64 {
    let bits = value as u64;
    for shift in (0..64).step_by(8) { h = (h ^ ((bits >> shift) & 255)).wrapping_mul(0x100000001b3); }
    h
}
#[no_mangle]
pub extern "C" fn generic_hash_map(a: *const i64, n: usize) -> i64 {
    if a.is_null() || n < 1 || n > 385 { return -1; }
    let x = unsafe { std::slice::from_raw_parts(a, n) };
    if x[0] < 0 || x[0] > 128 || n != 1 + 3 * x[0] as usize { return -1; }
    let mut keys=[0i64;MAX]; let mut vals=[0i64;MAX]; let mut next=[-1i32;MAX]; let mut active=[false;MAX];
    let mut head=[-1i32;128]; let mut size=0usize; let mut bc=16usize; let mut h=0xcbf29ce484222325u64;
    for oi in 0..x[0] as usize {
        let op=x[1+3*oi]; let key=x[2+3*oi]; let value=x[3+3*oi];
        if !(0..=1_000_000).contains(&key) { return -1; }
        let mut b=key as usize % bc; let mut found=-1i32; let mut j=head[b];
        while j>=0 { let q=j as usize; if keys[q]==key { found=j; break; } j=next[q]; }
        if op==0 {
            if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
            if found>=0 { vals[found as usize]=value; }
            else {
                if size>=MAX { return -1; }
                let q=active.iter().position(|v| !*v).unwrap(); active[q]=true; keys[q]=key; vals[q]=value; next[q]=head[b]; head[b]=q as i32; size+=1;
                if size*4>bc*3 && bc<128 { bc*=2; head.fill(-1); for q in 0..MAX { if active[q] { b=keys[q] as usize%bc; next[q]=head[b]; head[b]=q as i32; } } }
            }
        } else if op==1 || op==3 {
            if value!=0 { return -1; }
            h=hash_value(h, if op==1 { if found>=0 { vals[found as usize] } else { i64::MIN } } else { (found>=0) as i64 });
        } else if op==2 {
            if value!=0 { return -1; }
            if found>=0 { let mut prev=-1i32; let mut j=head[b]; while j>=0 { let q=j as usize; if j==found { if prev<0 {head[b]=next[q]} else {next[prev as usize]=next[q]} break; } prev=j; j=next[q]; } active[found as usize]=false; size-=1; }
        } else if op==4 { if key!=0||value!=0 {return -1;} h=hash_value(h,size as i64); }
        else {return -1;}
    }
    h=hash_value(h,size as i64); let mut used=[false;MAX];
    for _ in 0..size { let mut best=None; for i in 0..MAX { if active[i]&&!used[i]&&best.map_or(true,|q|keys[i]<keys[q]) {best=Some(i);} } let q=best.unwrap(); used[q]=true; h=hash_value(hash_value(h,keys[q]),vals[q]); }
    h as i64
}
