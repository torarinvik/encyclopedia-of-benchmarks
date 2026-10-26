fn put(out:&mut [u8],offset:usize,x:i64){out[offset..offset+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn first_fit_bin_packing(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1||length>65{return -1;}let v=unsafe{core::slice::from_raw_parts(input,length)};let n0=v[0];
    if !(0..=64).contains(&n0)||length!=1+n0 as usize{return -1;}let n=n0 as usize;
    if v[1..].iter().any(|&x|x<1||x>1_000_000){return -1;}
    let mut loads=[0i64;64];let mut ids=[0i64;64];let mut bins=0usize;
    for i in 0..n{let size=v[i+1];let mut b=0;while b<bins&&loads[b]+size>1_000_000{b+=1;}if b==bins{loads[bins]=size;bins+=1;}else{loads[b]+=size;}ids[i]=b as i64;}
    let required=(n+1)*8;if capacity<required||output.is_null(){return -2;}let out=unsafe{core::slice::from_raw_parts_mut(output,required)};put(out,0,bins as i64);for i in 0..n{put(out,8*(i+1),ids[i]);}required as i64
}
