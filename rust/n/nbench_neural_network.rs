#[no_mangle]
pub unsafe extern "C" fn nbench_neural_network(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let passes = *input;
    if !(1..=8).contains(&passes) { return -1; }
    if output.is_null() || capacity < 88 { return -2; }
    const PATTERN: [f64;35] = [0.,1.,1.,1.,0.,1.,0.,0.,0.,1.,1.,0.,0.,0.,1.,1.,0.,0.,0.,1.,1.,0.,0.,0.,1.,1.,0.,0.,0.,0.,0.,1.,1.,1.,0.];
    const TARGET: [f64;8] = [0.,1.,0.,0.,1.,1.,1.,1.];
    let mut mw=[[0.0f64;35];8]; let mut ow=[[0.0f64;8];8];
    let mut mc=[[0.0f64;35];8]; let mut oc=[[0.0f64;8];8];
    let mut mm=[[0.0f64;35];8]; let mut om=[[0.0f64;8];8];
    let mut mout=[0.0f64;8]; let mut oout=[0.0f64;8];
    for n in 0..8 { for w in 0..35 { mw[n][w]=(((n*17+w*7)%101) as i64-50) as f64/1000.0; } }
    for n in 0..8 { for w in 0..8 { ow[n][w]=(((n*13+w*5)%71) as i64-35) as f64/1000.0; } }
    for _ in 0..passes {
        for n in 0..8 { for w in 0..35 { mc[n][w]=mm[n][w]; mm[n][w]=0.0; } }
        for n in 0..8 { for w in 0..8 { oc[n][w]=om[n][w]; om[n][w]=0.0; } }
        for _ in 0..2 { for n in 0..8 { let mut sum=0.0; for w in 0..35 { sum+=mw[n][w]*PATTERN[w]; } mout[n]=1.0/(1.0+(-sum).exp()); } }
        for n in 0..8 { let mut sum=0.0; for w in 0..8 { sum+=ow[n][w]*mout[w]; } oout[n]=1.0/(1.0+(-sum).exp()); }
        let mut oe=[0.0f64;8]; let mut me=[0.0f64;8];
        for n in 0..8 { oe[n]=TARGET[n]-oout[n]; }
        for n in 0..8 { let mut sum=0.0; for i in 0..8 { sum+=ow[i][n]*oe[i]; } me[n]=mout[n]*(1.0-mout[n])*sum; }
        for n in 0..8 { for w in 0..8 { let mut d=0.09*oe[n]*mout[w]; d+=0.09*oc[n][w]; ow[n][w]+=d; om[n][w]+=d; } }
        for n in 0..8 { for w in 0..35 { let mut d=0.09*me[n]*PATTERN[w]; d+=0.09*mc[n][w]; mw[n][w]+=d; mm[n][w]+=d; } }
    }
    let mut result=[0i64;11]; result[0]=passes;
    for n in 0..8 { result[n+1]=(oout[n]*1_000_000.0) as i64; }
    let mut ms=0.0; let mut os=0.0;
    for n in 0..8 { for w in 0..35 { ms+=mw[n][w]; } }
    for n in 0..8 { for w in 0..8 { os+=ow[n][w]; } }
    result[9]=(ms*1_000_000.0) as i64; result[10]=(os*1_000_000.0) as i64;
    let bytes=core::slice::from_raw_parts_mut(output,88);
    for i in 0..11 { bytes[i*8..i*8+8].copy_from_slice(&result[i].to_le_bytes()); }
    88
}
