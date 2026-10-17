#[no_mangle]
pub unsafe extern "C" fn number_container_system(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<1{return -1}let count=*v;if !(0..=32).contains(&count)||n!=1+3*count as usize{return -1}
 let mut values=[0i64;64];let mut present=[false;64];let mut buf=[0u8;128];let mut used=0usize;
 for i in 0..count as usize{let op=*v.add(1+3*i);let a=*v.add(2+3*i);let b=*v.add(3+3*i);if op==0{if !(0..=63).contains(&a)||!(-100..=100).contains(&b){return -1}values[a as usize]=b;present[a as usize]=true;}else if op==1{if !(-100..=100).contains(&a)||b!=0{return -1}let mut found=-1;for j in 0..64{if present[j]&&values[j]==a{found=j as i64;break}}if used>0{buf[used]=b',';used+=1}let s=found.to_string();for byte in s.bytes(){buf[used]=byte;used+=1}}else{return -1}}
 if out.is_null()||used>cap{return -2}for i in 0..used{*out.add(i)=buf[i]}used as i64
}
