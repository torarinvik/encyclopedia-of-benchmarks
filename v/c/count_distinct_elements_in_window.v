module count_distinct_elements_in_window
fn put_i64_le(mut output &u8, offset int, value i64) {
    mut bits:=u64(value)
    for b in 0..8 { unsafe { output[offset+b]=u8(bits&255) }; bits >>= 8 }
}
@[export: 'count_distinct_elements_in_window']
pub fn count_distinct_elements_in_window(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe {input==nil} || length<3 {return -1}
    unsafe {
        if input[0]<1 || input[0]>256 {return -1}; n:=int(input[0])
        if input[1]<1 || input[1]>i64(n) || length!=usize(n+2) {return -1}
        k:=int(input[1]); out_n:=n-k+1
        for i in 0..n {if input[i+2]<-2147483648 || input[i+2]>2147483647 {return -1}}
        if capacity<usize(out_n*8) || output==nil {return -2}
        mut keys:=[256]i32{}; mut counts:=[256]i32{}; mut used:=0; mut distinct:=i64(0)
        for i in 0..k {v:=i32(input[i+2]); mut j:=0; for j<used && keys[j]!=v {j++}; if j==used {keys[j]=v;used++}; if counts[j]==0 {distinct++}; counts[j]++}
        put_i64_le(mut output,0,distinct)
        for i in k..n {incoming:=i32(input[i+2]); mut j:=0; for j<used && keys[j]!=incoming {j++}; if j==used {keys[j]=incoming;used++}; if counts[j]==0 {distinct++}; counts[j]++
            outgoing:=i32(input[i-k+2]); j=0; for keys[j]!=outgoing {j++}; counts[j]--; if counts[j]==0 {distinct--}; put_i64_le(mut output,(i-k+1)*8,distinct)
        }
        return i64(out_n*8)
    }
}
