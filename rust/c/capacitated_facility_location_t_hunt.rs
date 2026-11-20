const MAX_N: usize = 4;
const MAX_F: usize = 3;
const MAX_Q: usize = 4;
const MAX_P: usize = 7;
const NEG_INF: i64 = i64::MIN / 4;

unsafe fn put(out: *mut u8, at: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { *out.add(at + index) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn capacitated_facility_location_t_hunt(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 68 { return -1; }
    let nr = *input;
    let fr = *input.add(1);
    let qr = *input.add(2);
    let tr = *input.add(3);
    if nr < 1 || nr > MAX_N as i64 || fr < 1 || fr > MAX_F as i64
        || qr < 1 || qr > MAX_Q as i64 || tr < 0 || tr >= fr { return -1; }
    let n = nr as usize;
    let f = fr as usize;
    let q = qr as usize;
    let target = tr as usize;
    let points = n + f;
    if length != 4 + points * points + 2 * f + q + n { return -1; }
    let mut d = [[0i64; MAX_P]; MAX_P];
    let mut fee = [0i64; MAX_F];
    let mut capv = [0i64; MAX_F];
    let mut kind = [0usize; MAX_Q];
    let mut assigned = [0usize; MAX_N];
    let mut at = 4;
    for row in 0..points { for col in 0..points {
        let value = *input.add(at); at += 1;
        if !(0..=1000).contains(&value) { return -1; }
        d[row][col] = value;
    }}
    for i in 0..points {
        if d[i][i] != 0 { return -1; }
        for j in 0..points {
            if i != j && d[i][j] == 0 { return -1; }
            if d[i][j] != d[j][i] { return -1; }
            for k in 0..points { if d[i][j] > d[i][k] + d[k][j] { return -1; } }
        }
    }
    for i in 0..f { fee[i] = *input.add(at); at += 1; if !(0..=1000).contains(&fee[i]) { return -1; } }
    for i in 0..f { capv[i] = *input.add(at); at += 1; if capv[i] < 1 || capv[i] > nr { return -1; } }
    for i in 0..q { let v=*input.add(at);at+=1;if v<0||v>=fr{return -1;}kind[i]=v as usize; }
    for i in 0..n { let v=*input.add(at);at+=1;if v<0||v>=qr{return -1;}assigned[i]=v as usize; }
    let mut weight=[0i64;MAX_Q];let mut profit=[0i64;MAX_Q];let mut old=0i64;
    for c in 0..q { profit[c]=fee[kind[c]];old+=fee[kind[c]]; }
    for u in 0..n { let c=assigned[u];let source=kind[c];weight[c]+=1;if weight[c]>capv[source]{return -1;}let before=d[u][n+source];let after=d[u][n+target];old+=before;profit[c]-=after-before; }
    let mut result=[0i64,0,0,old,old];
    for copies in 1..=n {
        let limit=std::cmp::min(n,copies*capv[target] as usize);
        let mut dp=[NEG_INF;MAX_N+1];let mut masks=[0u32;MAX_N+1];dp[0]=0;
        for item in 0..q {
            let mut next=dp;let mut next_masks=masks;let iw=weight[item] as usize;
            if iw<=limit { for w in 0..=limit-iw { if dp[w]!=NEG_INF {let nw=w+iw;let value=dp[w]+profit[item];let mask=masks[w]|(1u32<<item);if value>next[nw]||(value==next[nw]&&mask<next_masks[nw]){next[nw]=value;next_masks[nw]=mask;}}}}
            dp=next;masks=next_masks;
        }
        let mut best=NEG_INF;let mut best_mask=0u32;for w in 0..=limit{if dp[w]>best||(dp[w]==best&&masks[w]<best_mask){best=dp[w];best_mask=masks[w];}}
        if best>(copies as i64)*fee[target]{result=[1,copies as i64,best_mask as i64,old,old+(copies as i64)*fee[target]-best];break;}
    }
    if output.is_null()||capacity<40{return -2;}for i in 0..5{put(output,8*i,result[i]);}40
}
