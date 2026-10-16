const INVALID:f64=-1.0e300;const SCALE:f64=1_000_000.0;
#[no_mangle]
pub unsafe extern "C" fn sparse_categorical_cross_entropy(values:*const i64,length:usize)->f64{
    if values.is_null() || length < 2 { return INVALID; }
    let batch = unsafe { *values }; let classes = unsafe { *values.add(1) };
    if !(1..=32).contains(&batch) || !(1..=32).contains(&classes) { return INVALID; }
    let b=batch as usize; let c=classes as usize;
    if length != 2+b+b*c { return INVALID; }
    for r in 0..b { let label=unsafe{*values.add(2+r)}; if label<0 || label>=classes {return INVALID;} let mut sum=0i64; for col in 0..c {let x=unsafe{*values.add(2+b+r*c+col)}; if x<0||x>1_000_000{return INVALID;} sum+=x;} if sum!=1_000_000{return INVALID;} }
    let mut total=0.0; for r in 0..b {let label=unsafe{*values.add(2+r)} as usize;let x=unsafe{*values.add(2+b+r*c+label)} as f64/SCALE;total+=-x.max(1e-15).min(1.0).ln();} total
}
