const MAX_N: usize = 16;
const MAX_M: usize = 8;

/// Preserve duplicate-need bookkeeping in the pinned Python demonstration.
#[no_mangle]
pub unsafe extern "C" fn bankers_algorithm_python_demo(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 5 || length > 266 { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    if !(1..=16).contains(&v[0]) || !(1..=8).contains(&v[1]) { return -1; }
    let (n,m) = (v[0] as usize, v[1] as usize);
    let (aoff,moff) = (2+m, 2+m+n*m);
    if length != moff+n*m { return -1; }
    let mut work=[0i64;MAX_M];
    for r in 0..m { let x=v[2+r]; if !(0..=100).contains(&x) {return -1;} work[r]=x; }
    for p in 0..n { for r in 0..m { let i=p*m+r; let a=v[aoff+i]; let x=v[moff+i]; if !(0..=100).contains(&a)||!(0..=100).contains(&x)||a>x{return -1;} work[r]-=a; } }
    if (0..m).any(|r|work[r]<0){return -1;}
    let mut first=[0usize;MAX_N]; let mut remaining=[0usize;MAX_N];
    for p in 0..n { first[p]=p; remaining[p]=p; for q in 0..p {
        let equal=(0..m).all(|r| {let pi=p*m+r;let qi=q*m+r;v[moff+pi]-v[aoff+pi]==v[moff+qi]-v[aoff+qi]});
        if equal {first[p]=first[q];break;}
    }}
    let mut count=n;
    while count>0 {
        let mut selected=count;
        for i in 0..count {let p=remaining[i];if (0..m).all(|r|{let j=p*m+r;v[moff+j]-v[aoff+j]<=work[r]}){selected=i;break;}}
        if selected==count{return 0;}
        let mapped=first[remaining[selected]];
        for r in 0..m {work[r]+=v[aoff+mapped*m+r];}
        for i in selected+1..count {remaining[i-1]=remaining[i];}
        count-=1;
    }
    1
}
