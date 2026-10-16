fn gcd_pos(mut a: i64, mut b: i64) -> i64 {
    a=a.abs(); b=b.abs();
    while b!=0 { let r=a%b; a=b; b=r; }
    a
}
unsafe fn put_i64(out:*mut u8,at:usize,value:i64){for(i,b)in value.to_le_bytes().iter().enumerate(){*out.add(at+i)=*b;}}
#[no_mangle]
pub unsafe extern "C" fn fraction(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
    if v.is_null()||n!=4{return -1} let a=std::slice::from_raw_parts(v,n);let(n1,d1,n2,d2)=(a[0],a[1],a[2],a[3]);
    if n1 < -10000||n1>10000||n2 < -10000||n2>10000||d1 < -1000||d1>1000||d2 < -1000||d2>1000||d1==0||d2==0{return -1}
    if out.is_null()||cap<16{return -2}let g=gcd_pos(d1,d2);let mut num=(d2/g)*n1+(d1/g)*n2;let mut den=(d1/g)*d2;let r=gcd_pos(num,den);num/=r;den/=r;if den<0{num=-num;den=-den}put_i64(out,0,num);put_i64(out,8,den);16
}
