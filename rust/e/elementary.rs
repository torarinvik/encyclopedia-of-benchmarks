#[no_mangle]
pub extern "C" fn elementary(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64 {
    if v.is_null()||n<2||n>129{return -1;} let a=unsafe{std::slice::from_raw_parts(v,n)};
    if a[0]<1||a[0]>128||n!=a[0] as usize+1||a[1]!=0||a[1..].iter().any(|x|*x!=0&&*x!=1){return -1;}
    let count=a[0] as usize;if cap<count||out.is_null(){return -2;}
    let result=unsafe{std::slice::from_raw_parts_mut(out,count)};
    for i in 0..count {let l=if i>0{a[i] as u32}else{0};let c=a[i+1] as u32;let r=if i+1<count{a[i+2] as u32}else{0};result[i]=((30u32>>(l*4+c*2+r))&1) as u8;}
    count as i64
}
