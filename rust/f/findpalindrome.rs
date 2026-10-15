const MAX_LENGTH: usize = 4096;
fn punctuation(value: i64) -> bool { (33..=47).contains(&value)||(58..=64).contains(&value)||(91..=96).contains(&value)||(123..=126).contains(&value) }
fn fold(value: i64) -> i64 { if (65..=90).contains(&value) { value+32 } else { value } }
#[no_mangle]
pub extern "C" fn findpalindrome(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if length>MAX_LENGTH||(length!=0&&input.is_null()) { return -1; }
    for i in 0..length { let v=unsafe{*input.add(i)}; if !(32..=126).contains(&v) { return -1; } }
    let mut written=0usize; let mut found=false; let mut segment=0usize;
    for end in 0..=length {
        if end<length&&unsafe{*input.add(end)}!=32 { continue; }
        let mut token_length=0usize;
        for i in segment..end { if !punctuation(unsafe{*input.add(i)}) { token_length+=1; } }
        let mut left=segment; let mut right=end; let mut matched=true;
        while left<right {
            while left<right&&punctuation(unsafe{*input.add(left)}) { left+=1; }
            while left<right&&punctuation(unsafe{*input.add(right-1)}) { right-=1; }
            if left<right { if fold(unsafe{*input.add(left)})!=fold(unsafe{*input.add(right-1)}) { matched=false; break; } left+=1; right-=1; }
        }
        if token_length>1&&matched {
            let needed=token_length+usize::from(found); if written+needed>output_capacity { return -2; }
            if found { unsafe{*output.add(written)=0}; written+=1; }
            for i in segment..end { let v=unsafe{*input.add(i)}; if !punctuation(v) { unsafe{*output.add(written)=v as u8}; written+=1; } }
            found=true;
        }
        segment=end+1;
    }
    written as i64
}
