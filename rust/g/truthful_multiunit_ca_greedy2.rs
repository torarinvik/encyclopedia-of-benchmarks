const MAX_ITEMS: usize = 6;
const MAX_BIDDERS: usize = 12;
const MAX_INPUT: usize = 32;
const MAX_OUTPUT: usize = 104;
fn put_i64(out: &mut [u8], at: usize, x: i64) { out[at..at+8].copy_from_slice(&x.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn truthful_multiunit_ca_greedy2(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let a=std::slice::from_raw_parts(values,length);
    if !(2..=MAX_ITEMS as i64).contains(&a[0]) || !(1..=MAX_BIDDERS as i64).contains(&a[1]) { return -1; }
    let items=a[0] as usize; let bidders=a[1] as usize; if length!=2+items+2*bidders { return -1; }
    let mut caps=[0usize;MAX_ITEMS]; let mut prices=[0.0f64;MAX_ITEMS]; let mut minimum=9usize;
    for e in 0..items { if !(1..=8).contains(&a[2+e]) { return -1; } caps[e]=a[2+e] as usize; minimum=minimum.min(caps[e]); prices[e]=1.0/caps[e] as f64; }
    let mut bids=[0i64;MAX_BIDDERS]; let mut masks=[0usize;MAX_BIDDERS];
    for i in 0..bidders { let value=a[2+items+2*i]; let mask=a[3+items+2*i]; if !(1..=100).contains(&value)||mask<1||mask>=(1i64<<items){return -1;} bids[i]=value;masks[i]=mask as usize; }
    let threshold=2.718281828459045f64.powf(minimum as f64)*items as f64; let mut chosen=[false;MAX_BIDDERS]; let mut order=[0usize;MAX_BIDDERS]; let mut count=0usize;
    while count<bidders { let mut best=None;let mut best_score=-1.0f64;
        for i in 0..bidders { if !chosen[i] { let mut denominator=0.0;for e in 0..items {if masks[i]&(1<<e)!=0{denominator+=prices[e];}}let score=bids[i] as f64/denominator;if best.is_none()||score>best_score{best=Some(i);best_score=score;} } }
        let Some(i)=best else {break};chosen[i]=true;order[count]=i;count+=1;
        for e in 0..items {if masks[i]&(1<<e)!=0{prices[e]*=threshold.powf(1.0/caps[e] as f64);}}
        let mut dual=0.0;for e in 0..items{dual+=caps[e] as f64*prices[e];}if dual>=threshold{break;}
    }
    let bytes=8*(1+count);if output.is_null()||capacity<bytes{return -2;}let mut staged=[0u8;MAX_OUTPUT];put_i64(&mut staged,0,count as i64);for i in 0..count{put_i64(&mut staged,8*(i+1),order[i] as i64);}std::ptr::copy_nonoverlapping(staged.as_ptr(),output,bytes);bytes as i64
}
