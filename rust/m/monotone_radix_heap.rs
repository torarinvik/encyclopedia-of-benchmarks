fn bucket_of(key: u32, last: u32) -> usize {
    let mut difference=key^last;
    let mut bits=0;
    while difference!=0 { bits+=1; difference>>=1; }
    bits
}

#[no_mangle]
pub unsafe extern "C" fn monotone_radix_heap(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=130).contains(&length) { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    if !(0..=64).contains(&values[0]) { return -1; }
    let q=values[0] as usize;
    if length!=1+2*q { return -1; }
    let mut buckets: [Vec<u32>;32]=std::array::from_fn(|_| Vec::new());
    let (mut last,mut count,mut result)=(0u32,0i64,0i64);
    for i in 0..q {
        let (op,key)=(values[1+2*i],values[2+2*i]);
        if op==0 {
            if key<i64::from(last) || key>2_147_483_647 { return -1; }
            let value=key as u32;
            buckets[bucket_of(value,last)].push(value);
        } else if op==1 && key==0 {
            if buckets[0].is_empty() {
                let index=match (1..32).find(|&j| !buckets[j].is_empty()) { Some(j)=>j, None=>return -1 };
                last=*buckets[index].iter().min().unwrap();
                for value in std::mem::take(&mut buckets[index]) {
                    buckets[bucket_of(value,last)].push(value);
                }
            }
            let value=buckets[0].pop().unwrap();
            count+=1; result+=count*i64::from(value);
        } else { return -1; }
    }
    result
}
