const MAX_N: usize = 12;

fn intersects(s: &[i64; MAX_N], e: &[i64; MAX_N], a: usize, b: usize) -> bool {
    s[a] <= e[b] && s[b] <= e[a]
}

unsafe fn write_u64_le(output: *mut u8, value: u64) {
    for b in 0..8 { *output.add(b) = (value >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn minimal_dominating_sets_interval(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 25 { return -1; }
    let n0=*input;
    if n0<1 || n0>MAX_N as i64 || length!=1+2*n0 as usize { return -1; }
    let n=n0 as usize; let mut s=[0i64;MAX_N];let mut e=[0i64;MAX_N];
    let(mut min_end,mut max_start)=(i64::MAX,i64::MIN);
    for i in 0..n {
        s[i]=*input.add(1+2*i);e[i]=*input.add(2+2*i);
        if s[i] < -100 || s[i] > 100 || e[i] < -100 || e[i] > 100 || s[i] >= e[i] || (i > 0 && s[i-1] >= s[i]) { return -1; }
        min_end=min_end.min(e[i]);max_start=max_start.max(s[i]);
        for j in 0..i {if s[i]==s[j]||s[i]==e[j]||e[i]==s[j]||e[i]==e[j]{return -1;}}
    }
    if output.is_null()||capacity<8{return -2;}
    let mut has_next=[false;MAX_N];let mut ncs=[0i64;MAX_N];let mut nce=[0i64;MAX_N];let mut p_single=[i64::MAX;MAX_N];
    for i in 0..n{for z in 0..n{
        if intersects(&s,&e,i,z){p_single[i]=p_single[i].min(e[z]);}
        if s[z]>e[i]{if !has_next[i]||s[z]<ncs[i]{ncs[i]=s[z];}if !has_next[i]||e[z]<nce[i]{nce[i]=e[z];}has_next[i]=true;}
    }}
    let mut valid=[[false;MAX_N];MAX_N];let mut p_pair=[[i64::MAX;MAX_N];MAX_N];
    for i in 0..n{for j in i+1..n{
        for z in 0..n{if intersects(&s,&e,j,z)&&!intersects(&s,&e,i,z){p_pair[i][j]=p_pair[i][j].min(e[z]);}}
        valid[i][j]=has_next[i]&&p_single[i]<s[j]&&s[j]<=nce[i]&&e[j]>=ncs[i];
    }}
    let mut ways=[[0i64;MAX_N];MAX_N];
    for j in 1..n{for i in 0..j{if !valid[i][j]{continue;}if s[i]<=min_end{ways[i][j]+=1;}
        for k in j+1..n{if valid[j][k]&&p_pair[i][j]<s[k]&&s[k]<=nce[j]{ways[j][k]+=ways[i][j];}}
    }}
    let mut count=0i64;for i in 0..n{if s[i]<=min_end&&e[i]>=max_start{count+=1;}}
    for i in 0..n{for j in i+1..n{if e[j]>=max_start{count+=ways[i][j];}}}
    write_u64_le(output,count as u64);8
}
