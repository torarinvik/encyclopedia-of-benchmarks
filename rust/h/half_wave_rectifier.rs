const BAD:f64=-1.0e300;
#[no_mangle]
pub unsafe extern "C" fn half_wave_rectifier(a:*const i64,n:usize)->f64{if a.is_null()||n!=5{return BAD;}let v=std::slice::from_raw_parts(a,n);if v[1..].iter().any(|&x|!(-1_000_000..=1_000_000).contains(&x)){return BAD;}match v[0]{0=>{if v[1]<0||v[2]<0||v[3]<0||(v[1]==0&&v[2]==0&&v[3]==0){BAD}else{v[4]as f64/(v[1]+v[2]+v[3])as f64}},1|2=>if v[2..].iter().any(|&x|x!=0){BAD}else{v[1]as f64*0.318},3=>if v[2]<=0||v[3]!=0||v[4]!=0{BAD}else{v[1]as f64/v[2]as f64},4|5=>if v[2..].iter().any(|&x|x!=0){BAD}else{v[1]as f64/2.0},_=>BAD}}
