const MAX_TEXT: usize = 32;
const MAX_PATTERN: usize = 8;

unsafe fn suffix_less(s: *const i64, n: usize, mut a: usize, mut b: usize) -> bool {
    while a < n && b < n {
        let x = *s.add(a); let y = *s.add(b);
        if x != y { return x < y; }
        a += 1; b += 1;
    }
    a == n && b != n
}

#[no_mangle]
pub unsafe extern "C" fn fm_index_count(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 42 { return -1; }
    let n0 = *input;
    if n0 < 1 || n0 > MAX_TEXT as i64 || length < n0 as usize + 3 { return -1; }
    let n = n0 as usize; let m_at = n + 1; let m0 = *input.add(m_at);
    if m0 < 1 || m0 > MAX_PATTERN as i64 || length != m_at + 1 + m0 as usize { return -1; }
    let m = m0 as usize; let total = n + 1;
    let mut s = [0i64; MAX_TEXT + 1]; let mut pattern = [0i64; MAX_PATTERN];
    for i in 0..n { let x = *input.add(1+i); if !(1..=4).contains(&x) { return -1; } s[i] = x; }
    for i in 0..m { let x = *input.add(m_at+1+i); if !(1..=4).contains(&x) { return -1; } pattern[i] = x; }
    s[n] = 0;
    if output.is_null() || capacity < 8 { return -2; }
    let mut sa = [0usize; MAX_TEXT + 1];
    for i in 0..total { sa[i] = i; }
    for i in 1..total { let key=sa[i]; let mut j=i; while j>0 && suffix_less(s.as_ptr(),total,key,sa[j-1]) {sa[j]=sa[j-1];j-=1;} sa[j]=key; }
    let mut bwt=[0i64;MAX_TEXT+1];let mut freq=[0usize;5];
    for i in 0..total {bwt[i]=s[(sa[i]+total-1)%total];freq[bwt[i] as usize]+=1;}
    let mut c=[0usize;5];let mut sum=0;for x in 0..5 {c[x]=sum;sum+=freq[x];}
    let(mut left,mut right)=(0usize,total);
    for k in (0..m).rev() {let symbol=pattern[k] as usize;let mut rl=0;let mut rr=0;for i in 0..left {if bwt[i] as usize==symbol{rl+=1;}}for i in 0..right{if bwt[i] as usize==symbol{rr+=1;}}left=c[symbol]+rl;right=c[symbol]+rr;if left==right{break;}}
    let count=(right-left) as u64;for i in 0..8{*output.add(i)=(count>>(8*i)) as u8;}8
}
