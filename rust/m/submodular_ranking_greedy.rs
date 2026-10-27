const MAX_N: usize = 5;
const MAX_M: usize = 4;
const MAX_INPUT: usize = 131;

unsafe fn store_i64_le(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *out.add(at+b) = (bits >> (8*b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn submodular_ranking_greedy(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64=*input; let m64=*input.add(1);
    if n64<1||n64>5||m64<1||m64>4{return -1;}
    let n=n64 as usize;let m=m64 as usize;let size=1usize<<n;
    if length!=2+m*size{return -1;}
    let mut f=[[0i64;32];4];
    for i in 0..m{
        for a in 0..size{let v=*input.add(2+i*size+a);if v<0||v>8{return -1;}f[i][a]=v;}
        if f[i][0]!=0||f[i][size-1]!=8{return -1;}
        for a in 0..size{for bit in 0..n{let e=1usize<<bit;if a&e==0&&f[i][a]>f[i][a|e]{return -1;}}}
        for a in 0..size{for b in 0..size{if a&b!=a{continue;}for bit in 0..n{let e=1usize<<bit;if b&e==0&&f[i][a|e]-f[i][a]<f[i][b|e]-f[i][b]{return -1;}}}}
    }
    let out_bytes=8*(1+n+m);if output.is_null()||capacity<out_bytes{return -2;}
    let mut order=[0usize;5];let mut times=[0i64;4];let mut total=0i64;let mut mask=0usize;
    for t in 1..=n{
        let mut winner=0usize;let mut best_num=-1i64;let mut best_den=1i64;
        for e in 0..n{let bit=1usize<<e;if mask&bit!=0{continue;}let mut num=0i64;let mut den=1i64;
            for i in 0..m{let cur=f[i][mask];if cur==8{continue;}let d=8-cur;let gain=f[i][mask|bit]-cur;num=num*d+gain*den;den*=d;}
            if best_num<0||num*best_den>best_num*den{winner=e;best_num=num;best_den=den;}
        }
        mask|=1usize<<winner;order[t-1]=winner;
        for i in 0..m{if times[i]==0&&f[i][mask]==8{times[i]=t as i64;total+=t as i64;}}
    }
    store_i64_le(output,0,total);for j in 0..n{store_i64_le(output,8*(1+j),order[j] as i64);}
    for i in 0..m{store_i64_le(output,8*(1+n+i),times[i]);}out_bytes as i64
}
