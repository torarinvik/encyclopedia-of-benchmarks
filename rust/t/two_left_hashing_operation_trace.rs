const QMAX: usize = 40;
const LIVE_MAX: usize = 32;
fn put(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { unsafe { out.add(at+b).write((bits>>(8*b)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn two_left_hashing_operation_trace(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 162 { return -1; }
    let qv = *input;
    if qv < 1 || qv > QMAX as i64 || length != 1 + 4*qv as usize { return -1; }
    let q=qv as usize;
    for i in 0..q {
        let op=*input.add(1+4*i); let key=*input.add(2+4*i);
        let left=*input.add(3+4*i); let right=*input.add(4+4*i);
        if !(0..=2).contains(&op)||!(0..=63).contains(&key)||!(0..=7).contains(&left)||!(0..=7).contains(&right){return -1;}
        for j in 0..i { if *input.add(2+4*j)==key && (*input.add(3+4*j)!=left||*input.add(4+4*j)!=right){return -1;} }
    }
    let bytes=16*q;if output.is_null()||capacity<bytes{return -2;}
    let mut head=[-1i32;16];let mut sizes=[0i32;16];let mut keys=[-1i64;32];let mut next=[-1i32;32];
    let mut statuses=[0i64;QMAX];let mut places=[-1i64;QMAX];let mut live=0usize;
    for i in 0..q {
        let base=1+4*i;let op=*input.add(base);let key=*input.add(base+1) as i64;
        let lb=*input.add(base+2) as usize;let rb=8+*input.add(base+3) as usize;
        let mut found=-1i32;let mut fb=0usize;
        for bucket in [lb,rb] {let mut x=head[bucket];while x>=0 {if keys[x as usize]==key{found=x;fb=bucket;break;}x=next[x as usize];}if found>=0{break;}}
        if op==0 {
            if found>=0{statuses[i]=0;continue;}if live==LIVE_MAX{return -3;}
            let left=sizes[lb]<=sizes[rb];let bucket=if left{lb}else{rb};let node=keys.iter().position(|&v|v<0).unwrap();
            keys[node]=key;next[node]=head[bucket];head[bucket]=node as i32;sizes[bucket]+=1;live+=1;statuses[i]=1;places[i]=if left{0}else{1};
        } else if op==1 {statuses[i]=if found>=0{1}else{0};}
        else if found>=0 {let mut prev=-1i32;let mut x=head[fb];while x!=found{prev=x;x=next[x as usize];}if prev<0{head[fb]=next[x as usize];}else{next[prev as usize]=next[x as usize];}keys[x as usize]=-1;next[x as usize]=-1;sizes[fb]-=1;live-=1;statuses[i]=1;}
    }
    for i in 0..q {put(output,16*i,statuses[i]);put(output,16*i+8,places[i]);}
    bytes as i64
}
