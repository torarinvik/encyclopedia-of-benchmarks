const MAX_OPS: usize = 32;
const MAX_INPUT: usize = 98;
fn find_key(keys: &[i64; MAX_OPS], n: usize, key: i64) -> usize { (0..n).find(|&i| keys[i] == key).unwrap_or(n) }
fn swap_items(keys: &mut [i64; MAX_OPS], ps: &mut [i64; MAX_OPS], a: usize, b: usize) { keys.swap(a,b); ps.swap(a,b); }
fn shift_up(keys: &mut [i64; MAX_OPS], ps: &mut [i64; MAX_OPS], mut i: usize) {
    while i > 0 { let p = (i-1)/2; if ps[p] <= ps[i] { break; } swap_items(keys,ps,p,i); i=p; }
}
fn shift_down(keys: &mut [i64; MAX_OPS], ps: &mut [i64; MAX_OPS], n: usize, mut i: usize) {
    while 2*i+1 < n { let l=2*i+1; let r=l+1;
        let c = if ps[l] < ps[i] && (r >= n || ps[l] < ps[r]) { Some(l) } else if r < n && ps[r] < ps[i] { Some(r) } else { None };
        match c { Some(child) => { swap_items(keys,ps,i,child); i=child; }, None => break }
    }
}
#[no_mangle]
pub extern "C" fn key_priority_queue(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input,length) };
    if !(0..=MAX_OPS as i64).contains(&a[0]) { return -1; }
    let mut keys=[0i64;MAX_OPS]; let mut ps=[0i64;MAX_OPS]; let mut answers=[0i64;MAX_OPS];
    let (mut n,mut out_n,mut pos)=(0usize,0usize,1usize);
    for _ in 0..a[0] as usize {
        if pos>=length { return -1; } let op=a[pos];
        if op==0 || op==1 {
            if pos+2>=length { return -1; } let key=a[pos+1]; let priority=a[pos+2];
            if !(-1_000_000_000..=1_000_000_000).contains(&key) || !(-1_000_000_000..=1_000_000_000).contains(&priority) { return -1; }
            pos+=3; let found=find_key(&keys,n,key);
            if op==0 { if found!=n { return -1; } keys[n]=key; ps[n]=priority; shift_up(&mut keys,&mut ps,n); n+=1; }
            else if found==n { keys[n]=key; ps[n]=priority; shift_up(&mut keys,&mut ps,n); n+=1; }
            else { ps[found]=priority;
                if found>0 && ps[(found-1)/2]>priority { shift_up(&mut keys,&mut ps,found); }
                else { let l=2*found+1; let r=l+1; if (l<n && ps[l]<priority)||(r<n && ps[r]<priority) { shift_down(&mut keys,&mut ps,n,found); } }
            }
        } else if op==2 { pos+=1; if n==0 { return -1; } swap_items(&mut keys,&mut ps,0,n-1); n-=1; answers[out_n]=keys[n]; out_n+=1; if n>0 { shift_down(&mut keys,&mut ps,n,0); } }
        else if op==3 { if pos+1>=length { return -1; } let key=a[pos+1]; if !(-1_000_000_000..=1_000_000_000).contains(&key) { return -1; } pos+=2; answers[out_n]=if find_key(&keys,n,key)!=n { 1 } else { 0 }; out_n+=1; }
        else if op==4 { pos+=1; answers[out_n]=if n==0 { 1 } else { 0 }; out_n+=1; }
        else { return -1; }
    }
    if pos!=length { return -1; } let bytes=out_n*8;
    if output.is_null() || output_capacity<bytes { return -2; }
    unsafe { for i in 0..out_n { for b in 0..8 { *output.add(i*8+b)=((answers[i] as u64)>>(8*b)) as u8; } } }
    bytes as i64
}
