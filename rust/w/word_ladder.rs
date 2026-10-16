/// Java WordLadder shortest sequence length over bounded base-26 words.
#[no_mangle]
pub unsafe extern "C" fn word_ladder(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let x = std::slice::from_raw_parts(input, length);
    let (width,start,end,count)=(x[0],x[1],x[2],x[3]);
    if !(1..=5).contains(&width) || !(0..=32).contains(&count) || length != 4+count as usize { return -1; }
    let limit=26i64.pow(width as u32);
    if start<0||start>=limit||end<0||end>=limit||x[4..].iter().any(|&v|v<0||v>=limit){return -1;}
    let words=&x[4..];
    let mut result=0i64;
    if words.contains(&end){
        let mut queue=vec![(start,1i64)]; let mut cursor=0;
        while cursor<queue.len()&&result==0 {let(cur,d)=queue[cursor];cursor+=1;let mut factor=1i64;
            for _ in 0..width {let digit=(cur/factor)%26;for ch in 0..26 {if ch==digit{continue}let next=cur+(ch-digit)*factor;
                if next==end {result=d+1;break}
                if words.contains(&next)&&!queue.iter().any(|&(v,_)|v==next){queue.push((next,d+1));}
            }if result!=0{break}factor*=26;}
        }
    }
    if output.is_null()||capacity<8{return -2;}
    std::ptr::copy_nonoverlapping(result.to_le_bytes().as_ptr(),output,8);8
}
