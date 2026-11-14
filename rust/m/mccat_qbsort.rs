const MAX_ITEMS: usize = 32;
use std::collections::LinkedList;
fn bubble(a: &mut [i32]) {
    for end in (1..a.len()).rev() { for i in 0..end { if a[i+1] < a[i] { a.swap(i,i+1); } } }
}
fn quick(items: &LinkedList<i32>) -> LinkedList<i32> {
    let mut iter = items.iter();
    let Some(&pivot) = iter.next() else { return LinkedList::new(); };
    let mut lower = LinkedList::new();
    let mut upper = LinkedList::new();
    for &value in iter {
        if value < pivot { lower.push_front(value); }
        else { upper.push_front(value); }
    }
    let mut sorted_upper = quick(&upper);
    let mut sorted_lower = quick(&lower);
    sorted_lower.push_back(pivot);
    sorted_lower.append(&mut sorted_upper);
    sorted_lower
}
#[no_mangle]
pub unsafe extern "C" fn mccat_qbsort(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3||length>2+MAX_ITEMS{return -1} let x=std::slice::from_raw_parts(input,length);let(mode,cv)=(x[0],x[1]);
    if(mode!=0&&mode!=1)||cv<1||cv>MAX_ITEMS as i64{return -1}let n=cv as usize;if length!=n+2{return -1}
    let mut a=[0i32;MAX_ITEMS];for i in 0..n{if x[i+2]<i32::MIN as i64||x[i+2]>i32::MAX as i64{return -1}a[i]=x[i+2] as i32;}
    for _ in 0..1000{
        for i in 0..n{a[i]=x[i+2] as i32;}
        if mode==0{bubble(&mut a[..n])}else{
            let items: LinkedList<i32> = a[..n].iter().copied().collect();
            let sorted = quick(&items);
            for (slot, &value) in a[..n].iter_mut().zip(sorted.iter()){*slot=value;}
        }
    }
    let need=4*n;if output.is_null()||capacity<need{return -2}for i in 0..n{let bytes=a[i].to_le_bytes();for b in 0..4{*output.add(4*i+b)=bytes[b]}}need as i64
}
