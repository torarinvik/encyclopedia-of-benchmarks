fn put(out:&mut[u8],offset:usize,x:i64){out[offset..offset+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn deterministic_line_search(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length!=1{return -1;}let target=unsafe{*input};if target==0||target< -50_000||target>50_000{return -1;}
 let distance=target.abs();let mut traveled=0i64;let mut leg=0i64;let mut depth=1i64;
 loop{let negative=leg%2==0;if((target<0)==negative)&&distance<=depth{traveled+=distance;break;}traveled+=2*depth;depth*=2;leg+=1;}
 if capacity<16||output.is_null(){return -2;}let out=unsafe{core::slice::from_raw_parts_mut(output,16)};put(out,0,traveled);put(out,8,leg);16
}
