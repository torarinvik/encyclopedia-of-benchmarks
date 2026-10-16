#[no_mangle]
pub unsafe extern "C" fn pig_latin(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<1||n>65{return -1} let a=std::slice::from_raw_parts(v,n);
 if !(0..=64).contains(&a[0])||n!=a[0] as usize+1{return -1} let count=a[0] as usize;
 if count==0{return 0}if count+3>cap||out.is_null(){return -2}
 let dst=std::slice::from_raw_parts_mut(out,cap);let mut pivot=count;
 for i in 0..count{let mut x=a[i+1];if (65..=90).contains(&x){x+=32}if !(97..=122).contains(&x){return -1}dst[i]=x as u8;if pivot==count&&(x==97||x==101||x==105||x==111||x==117){pivot=i}}
 if pivot==count{return -1} let size=if pivot==0{count+3}else{count+2};if size>cap{return -2}
 if pivot==0{dst[count..count+3].copy_from_slice(b"way")}else{dst.copy_within(0..pivot,count);dst.copy_within(pivot..count,0);dst[count]=b'a';dst[count+1]=b'y'}
 size as i64
}
