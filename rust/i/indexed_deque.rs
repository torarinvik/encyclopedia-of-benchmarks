#[no_mangle]
pub unsafe extern "C" fn indexed_deque(input: *const i64, length: usize,
                                        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=513).contains(&length) { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    if !(1..=256).contains(&values[0]) { return -1; }
    let q=values[0] as usize;
    if length!=1+2*q { return -1; }
    let mut items=[0i64;256]; let mut answers=[0i64;256];
    let (mut head,mut size,mut count)=(0usize,0usize,0usize);
    for record in values[1..].chunks_exact(2) {
        let (op,arg)=(record[0],record[1]);
        match op {
            0 | 1 => {
                if !(-1_000_000..=1_000_000).contains(&arg) || size==256 { return -1; }
                if op==0 { head=(head+255)%256; items[head]=arg; }
                else { items[(head+size)%256]=arg; }
                size+=1;
            }
            2 | 3 => {
                if arg!=0 || size==0 { return -1; }
                if op==2 { head=(head+1)%256; }
                size-=1;
            }
            4 => {
                if arg<0 || arg>=size as i64 { return -1; }
                answers[count]=items[(head+arg as usize)%256]; count+=1;
            }
            _ => return -1,
        }
    }
    if count==0 { return -1; }
    if output.is_null() || capacity<8*count { return -2; }
    for (i,answer) in answers[..count].iter().enumerate() {
        std::ptr::copy_nonoverlapping(answer.to_le_bytes().as_ptr(),output.add(8*i),8);
    }
    (8*count) as i64
}
