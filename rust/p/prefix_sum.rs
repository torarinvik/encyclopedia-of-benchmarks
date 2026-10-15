const MAX_LENGTH: usize = 256;
const HASH_CAPACITY: usize = 1024;
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) { output[offset..offset+8].copy_from_slice(&value.to_le_bytes()); }
fn hash_key(key: i64) -> usize { key.rem_euclid(HASH_CAPACITY as i64) as usize }
fn contains_sum(prefix: &[i64], n: usize, target: i64) -> bool {
    let mut keys=[0i64;HASH_CAPACITY];let mut used=[false;HASH_CAPACITY];let mut slot=hash_key(0);used[slot]=true;keys[slot]=0;
    for end in 1..=n { let wanted=prefix[end]-target;slot=hash_key(wanted);while used[slot]&&keys[slot]!=wanted{slot=(slot+1)%HASH_CAPACITY;}if used[slot]{return true;}
        slot=hash_key(prefix[end]);while used[slot]&&keys[slot]!=prefix[end]{slot=(slot+1)%HASH_CAPACITY;}if !used[slot]{used[slot]=true;keys[slot]=prefix[end];}}
    false
}
#[no_mangle]
pub unsafe extern "C" fn prefix_sum(raw: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if raw.is_null()||length<2{return -1;}let input=std::slice::from_raw_parts(raw,length);
    if !(0..=2).contains(&input[0])||input[1]<0||input[1]>MAX_LENGTH as i64{return -1;}let op=input[0];let n=input[1] as usize;
    let extra=if op==1{2}else if op==2{1}else{0};
    if length!=2+n+extra||(op==1&&n==0){return -1;}
    let values=&input[2..2+n];if values.iter().any(|v|*v<i32::MIN as i64||*v>i32::MAX as i64){return -1;}
    if op==1{let left=input[2+n];let right=input[3+n];if left<0||right<left||right>=n as i64{return -1;}}
    else if op==2&&input[2+n].unsigned_abs()>1_000_000_000_000u64{return -1;}
    let mut prefix=[0i64;MAX_LENGTH+1];for i in 0..n{prefix[i+1]=prefix[i]+values[i];}
    let words=if op==0{n}else{1};if capacity<words*8||(words>0&&output.is_null()){return -2;}
    if words == 0 { return 0; }
    let out=std::slice::from_raw_parts_mut(output,words*8);
    if op==0{for i in 0..n{store_i64_le(out,i*8,prefix[i+1]);}return n as i64;}
    let result=if op==1{prefix[input[3+n] as usize+1]-prefix[input[2+n] as usize]}else{i64::from(contains_sum(&prefix,n,input[2+n]))};store_i64_le(out,0,result);1
}
