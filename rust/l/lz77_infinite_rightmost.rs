const MAX_TEXT: usize = 64;
const MAX_INPUT: usize = 66;
const MAX_OUTPUT: usize = 1536;
unsafe fn put64(out: *mut u8, at: usize, value: i64) { let b=value as u64; for i in 0..8 { *out.add(at+i)=(b>>(8*i)) as u8; } }
#[no_mangle]
pub unsafe extern "C" fn lz77_infinite_rightmost(input:*const i64,len:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||len<1||len>MAX_INPUT{return -1;} let n64=*input;
    if n64<0||n64>MAX_TEXT as i64{return -1;} let n=n64 as usize;if len!=n+1{return -1;}
    for i in 0..n {let c=*input.add(i+1);if !(32..=126).contains(&c){return -1;}}
    let mut staged=[0u8;MAX_OUTPUT];let mut tokens=0usize;let mut q=0usize;
    while q<n {let mut bl=0usize;let mut bp=0usize;let mut found=false;
        for p in 0..q {let mut l=0usize;while q+l<n&&*input.add(p+l+1)==*input.add(q+l+1){l+=1;}
            if l>bl||(l==bl&&l>0&&(!found||p>bp)){bl=l;bp=p;found=true;}}
        let source_pos=if found{bp as i64}else{0};let np=q+bl;let ch=if np<n{*input.add(np+1)}else{0};let at=tokens*24;
        put64(staged.as_mut_ptr(),at,source_pos);put64(staged.as_mut_ptr(),at+8,bl as i64);put64(staged.as_mut_ptr(),at+16,ch);tokens+=1;q=if ch!=0{np+1}else{np};
    }
    let bytes=tokens*24;if output.is_null()||capacity<bytes{return -2;}for i in 0..bytes{*output.add(i)=staged[i];}bytes as i64
}
