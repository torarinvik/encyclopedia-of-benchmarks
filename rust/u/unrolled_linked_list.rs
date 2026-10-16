#[no_mangle]
pub unsafe extern "C" fn unrolled_linked_list_benchmark(values: *const i64, length: usize) -> i64 {
    if length > 1024 { return -1; }
    let mut chunks = [[0_i64; 5]; 512];
    let mut counts = [0_usize; 512];
    let mut next = [512_usize; 512];
    let mut blocks = 0_usize;
    for i in 0..length {
        let value = *values.add(i);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        if blocks == 0 { blocks=1; counts[0]=1; chunks[0][0]=value; continue; }
        let tail=blocks-1;
        if counts[tail] < 4 { chunks[tail][counts[tail]]=value; counts[tail]+=1; }
        else { let keep=counts[tail]/2+1; let moved=counts[tail]-keep;
            for j in 0..moved { chunks[blocks][j]=chunks[tail][keep+j]; }
            counts[tail]=keep; chunks[blocks][moved]=value; counts[blocks]=moved+1; next[tail]=blocks; blocks+=1;
        }
    }
    let mut sum=0_i64; let mut index=0_i64;
    let mut b=0; while b < 512 { for j in 0..counts[b] { sum+=(index+1)*(chunks[b][j]+1_000_000); index+=1; } if next[b]==512 { break; } b=next[b]; }
    sum
}
