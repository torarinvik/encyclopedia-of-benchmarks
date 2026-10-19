const MAX_ITEMS: usize = 32;
fn bubble(a: &mut [i32]) {
    for end in (1..a.len()).rev() { for i in 0..end { if a[i+1] < a[i] { a.swap(i,i+1); } } }
}
fn quick(a: &mut [i32]) {
    if a.len()<2{return} let pivot=a[0]; let mut lower=[0i32;MAX_ITEMS]; let mut upper=[0i32;MAX_ITEMS]; let(mut nl,mut nu)=(0,0);
    for &v in &a[1..] { if v<pivot {lower[nl]=v;nl+=1} else {upper[nu]=v;nu+=1} }
    quick(&mut upper[..nu]); quick(&mut lower[..nl]); let mut k=0;
    for &v in &lower[..nl] {a[k]=v;k+=1} a[k]=pivot;k+=1; for &v in &upper[..nu] {a[k]=v;k+=1}
}
#[no_mangle]
pub unsafe extern "C" fn mccat_qbsort(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3||length>2+MAX_ITEMS{return -1} let x=std::slice::from_raw_parts(input,length);let(mode,cv)=(x[0],x[1]);
    if(mode!=0&&mode!=1)||cv<1||cv>MAX_ITEMS as i64{return -1}let n=cv as usize;if length!=n+2{return -1}
    let mut a=[0i32;MAX_ITEMS];for i in 0..n{if x[i+2]<i32::MIN as i64||x[i+2]>i32::MAX as i64{return -1}a[i]=x[i+2] as i32;}
    for _ in 0..1000{for i in 0..n{a[i]=x[i+2] as i32;}if mode==0{bubble(&mut a[..n])}else{quick(&mut a[..n])}}
    let need=4*n;if output.is_null()||capacity<need{return -2}for i in 0..n{let bytes=a[i].to_le_bytes();for b in 0..4{*output.add(4*i+b)=bytes[b]}}need as i64
}
