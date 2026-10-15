/// Evaluate net present value for each supplied discount rate.
fn put_f64_le(out:&mut [u8],offset:usize,value:f64){out[offset..offset+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn npv_sensitivity(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<2{return -1;}
    let values=std::slice::from_raw_parts(input,length);let n64=values[0];let rates64=values[1];
    if !(0..=64).contains(&n64)||!(0..=32).contains(&rates64){return -1;}
    let n=n64 as usize;let rates=rates64 as usize;if length!=2+n+rates{return -1;}
    if values[2..2+n].iter().any(|v|!(-1_000_000..=1_000_000).contains(v))||values[2+n..].iter().any(|v|!(0..=1000).contains(v)){return -1;}
    if capacity<rates*8||(rates>0&&output.is_null()){return -2;}if rates==0{return 0;}
    let out=std::slice::from_raw_parts_mut(output,rates*8);
    for r in 0..rates{let rate=values[2+n+r] as f64/10000.0;let mut total=0.0f64;for(t,&flow)in values[2..2+n].iter().enumerate(){let term=flow as f64/(1.0+rate).powi(t as i32);total+=term;}put_f64_le(out,r*8,total);}
    (rates*8) as i64
}
