#[no_mangle]
pub unsafe extern "C" fn word_patterns(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values=std::slice::from_raw_parts(input,length); if !(0..=256).contains(&values[0]) || length!=values[0] as usize+1 {return -1;}
    let n=values[0] as usize;
    let mut first=[-1i32;128]; let mut next=0i32; let mut pos=0usize;
    for i in 0..n { let mut ch=values[i+1]; if !(0..=127).contains(&ch) {return -1;} if (b'a' as i64..=b'z' as i64).contains(&ch){ch-=32;} let c=ch as usize; if first[c]<0 {first[c]=next;next+=1;} }
    if output.is_null() || capacity<4*n+1 {return -2;}
    let out=std::slice::from_raw_parts_mut(output,capacity);
    for i in 0..n {let mut ch=values[i+1];if (b'a' as i64..=b'z' as i64).contains(&ch){ch-=32;}let c=ch as usize;if i>0 {out[pos]=b'.';pos+=1;} let mut num=first[c] as usize; let mut ds=[0u8;3];let mut k=0;loop{ds[k]=b'0'+(num%10) as u8;k+=1;num/=10;if num==0{break;}} while k>0{k-=1;out[pos]=ds[k];pos+=1;} }
    out[pos]=0;pos as i64
}
