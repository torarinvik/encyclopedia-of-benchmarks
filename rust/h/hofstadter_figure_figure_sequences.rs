const MAX_TERMS: usize = 64;
const MAX_WORDS: usize = 129;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset+8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn hofstadter_figure_figure_sequences(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > 2 { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_TERMS as i64 || length != 1 { return -1; }
    let n=n_value as usize;
    let mut figure=[0i64;MAX_TERMS];
    let mut space=[0i64;MAX_TERMS];
    figure[0]=1; space[0]=2;
    let mut candidate=3i64;
    for i in 1..n {
        figure[i]=figure[i-1]+space[i-1];
        loop {
            let mut used=false;
            for j in 0..=i { if figure[j]==candidate { used=true; } }
            if !used { break; }
            candidate+=1;
        }
        space[i]=candidate;
        candidate+=1;
    }
    let count=1+2*n; let bytes=count*8;
    if output.is_null() || capacity<bytes { return -2; }
    let mut words=[0i64;MAX_WORDS];
    words[0]=n as i64;
    for i in 0..n { words[1+i]=figure[i]; words[1+n+i]=space[i]; }
    let output_slice=std::slice::from_raw_parts_mut(output,bytes);
    for i in 0..count { write_i64_le(output_slice,i*8,words[i]); }
    bytes as i64
}
