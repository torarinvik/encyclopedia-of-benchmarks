const MAX_N: usize = 8;
const MAX_K: usize = 8;
const MAX_INPUT: usize = 75;

unsafe fn put64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn radio_network_decay_phase(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64=*input; let k64=*input.add(1); let initial=*input.add(2);
    if n64<2 || n64>MAX_N as i64 || k64<1 || k64>MAX_K as i64 || length!=3+n64 as usize+n64 as usize*k64 as usize { return -1; }
    let n=n64 as usize; let k=k64 as usize; let full=(1_u64<<n)-1;
    if initial<=0 || (initial as u64)&!full!=0 { return -1; }
    let mut adjacency=[0_u64;MAX_N];
    for v in 0..n { let raw=*input.add(3+v); if raw<0 || (raw as u64)&!full!=0 || (raw as u64)&(1_u64<<v)!=0 { return -1; } adjacency[v]=raw as u64; }
    for u in 0..n { for v in 0..n { if (adjacency[u]>>v)&1 != (adjacency[v]>>u)&1 { return -1; } } }
    let tape_at=3+n;
    for i in 0..n*k { let bit=*input.add(tape_at+i); if bit!=0 && bit!=1 { return -1; } }
    if output.is_null() || capacity<16 { return -2; }
    let mut active=[false;MAX_N]; for v in 0..n { active[v]=((initial as u64>>v)&1)!=0; }
    let mut newly=0_u64; let mut transmissions=0_i64;
    for slot in 0..k {
        for sender in 0..n { if active[sender] { transmissions+=1; } }
        for receiver in 0..n {
            if ((initial as u64>>receiver)&1)!=0 { continue; }
            let mut count=0;
            for sender in 0..n { if active[sender] && (adjacency[sender]>>receiver)&1!=0 { count+=1; } }
            if count==1 { newly|=1_u64<<receiver; }
        }
        for sender in 0..n { if active[sender] && (*input.add(tape_at+sender*k+slot)==0 || slot+1==k) { active[sender]=false; } }
    }
    let mut staged=[0_u8;16]; put64(staged.as_mut_ptr(),0,newly as i64); put64(staged.as_mut_ptr(),8,transmissions);
    for byte in 0..16 { *output.add(byte)=staged[byte]; }
    16
}
