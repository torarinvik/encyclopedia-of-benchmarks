#[no_mangle]
pub extern "C" fn quadratic_residue(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, 2) };
    let (a,p)=(v[0],v[1]);
    if ![3,5,7,11,13,17,19,23,29,31,37,41,43,47,53].contains(&p) || a<0 || a>=p { return -1; }
    if a==0 { return 0; }
    let(mut r,mut b,mut e)=(1i64,a,(p-1)/2);
    while e>0 { if e&1!=0 {r=r*b%p;} b=b*b%p; e>>=1; }
    if r==1 {1} else {-1}
}
