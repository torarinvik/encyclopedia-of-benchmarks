const MAX_TARGET: usize = 6;
const MAX_WORDS: usize = 4;
const MAX_WAYS: usize = 4096;

#[no_mangle]
pub unsafe extern "C" fn all_construct(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let a=std::slice::from_raw_parts(input,length);
    if !(0..=MAX_TARGET as i64).contains(&a[0]) { return -1; }
    let n=a[0] as usize;
    if a[1..1+n].iter().any(|&b| !(b'a' as i64..=b'z' as i64).contains(&b)) { return -1; }
    let ws=1+n;if ws>=length||!(0..=MAX_WORDS as i64).contains(&a[ws]){return -1;}
    let words=a[ws] as usize;let mut cursor=ws+1;let mut starts=[0usize;MAX_WORDS];let mut wlens=[0usize;MAX_WORDS];
    for w in 0..words {if cursor>=length||a[cursor]<1||a[cursor]>MAX_TARGET as i64{return -1;}let size=a[cursor] as usize;cursor+=1;if cursor+size>length{return -1;}if a[cursor..cursor+size].iter().any(|&b|!(b'a' as i64..=b'z' as i64).contains(&b)){return -1;}starts[w]=cursor;wlens[w]=size;cursor+=size;}
    if cursor!=length{return -1;}
    let mut paths=[[[0u8;MAX_TARGET];MAX_WAYS];MAX_TARGET+1];let mut plen=[[0u8;MAX_WAYS];MAX_TARGET+1];let mut counts=[0usize;MAX_TARGET+1];counts[0]=1;
    for pos in 0..n {for w in 0..words {let size=wlens[w];if size>n-pos{continue;}if (0..size).any(|j|a[pos+1+j]!=a[starts[w]+j]){continue;}let end=pos+size;for r in 0..counts[pos]{let dest=counts[end];if dest>=MAX_WAYS{return -1;}counts[end]+=1;let k=plen[pos][r] as usize;for x in 0..k{paths[end][dest][x]=paths[pos][r][x];}paths[end][dest][k]=w as u8;plen[end][dest]=(k+1) as u8;}}}
    let mut required=0usize;for r in 0..counts[n]{required+=1;for k in 0..plen[n][r] as usize{let w=paths[n][r][k] as usize;required+=1+wlens[w];}}if capacity<required||(required!=0&&output.is_null()){return -2;}
    if required==0{return counts[n] as i64;}
    let out=std::slice::from_raw_parts_mut(output,required);let mut written=0;
    for r in 0..counts[n]{let k=plen[n][r] as usize;out[written]=k as u8;written+=1;for x in 0..k{let w=paths[n][r][x] as usize;out[written]=wlens[w] as u8;written+=1;for j in 0..wlens[w]{out[written]=a[starts[w]+j] as u8;written+=1;}}}
    counts[n] as i64
}
