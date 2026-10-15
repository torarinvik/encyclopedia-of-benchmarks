#[no_mangle]
pub unsafe extern "C" fn fast_inverse_sqrt_java_check(input:*const i64,length:usize)->i64{
    if input.is_null()||length!=2{return -1;}
    let values=std::slice::from_raw_parts(input,length);
    if values[0]==0{
        if !(0x00800000..=0x7f7fffff).contains(&values[1]){return -1;}
        let number=f32::from_bits(values[1] as u32);let xhalf=0.5_f32*number;
        let seed=0x5f3759df_u32-((values[1] as u32)>>1);let mut x=f32::from_bits(seed);
        x=x*(1.5_f32-xhalf*x*x);
        let expected=1.0_f32/(number.sqrt());return if x==expected{1}else{0};
    }
    if values[0]==1{
        if values[1]<0x0010000000000000||values[1]>0x7fefffffffffffff{return -1;}
        let number=f64::from_bits(values[1] as u64);let xhalf=0.5_f64*number;
        let seed=0x5fe6ec85e7de30da_u64-((values[1] as u64)>>1);let mut x=f64::from_bits(seed);
        for _ in 0..4{x=x*(1.5_f64-xhalf*x*x);}
        x*=number;return if x==1.0_f64/number.sqrt(){1}else{0};
    }
    -1
}
