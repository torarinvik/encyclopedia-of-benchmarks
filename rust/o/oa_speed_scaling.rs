const MAX_JOBS: usize = 2;
const MAX_INPUT: usize = 8;
const MAX_OUTPUT: usize = 152;

#[derive(Clone, Copy)]
struct Rat { n: i64, d: i64 }
#[derive(Clone, Copy, Default)]
struct Segment { start: i64, end: i64, speed_n: i64, speed_d: i64 }

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r = a % b; a = b; b = r; }
    if a < 0 { -a } else { a }
}
fn make(n: i64, d: i64) -> Rat {
    let (n,d) = if d < 0 { (-n,-d) } else { (n,d) };
    let g = gcd(n,d); Rat { n: n/g, d: d/g }
}
fn add(a: Rat,b: Rat) -> Rat { make(a.n*b.d+b.n*a.d,a.d*b.d) }
fn sub(a: Rat,b: Rat) -> Rat { make(a.n*b.d-b.n*a.d,a.d*b.d) }
fn mul(a: Rat,b: Rat) -> Rat { make(a.n*b.n,a.d*b.d) }
fn div(a: Rat,b: Rat) -> Rat { make(a.n*b.d,a.d*b.n) }
fn integer(x: i64) -> Rat { Rat { n:x, d:1 } }
fn cmp(a: Rat,b: Rat) -> i32 {
    let left=a.n*b.d; let right=b.n*a.d;
    if left>right { 1 } else if left<right { -1 } else { 0 }
}
fn append_segment(segments: &mut [Segment;3], count: &mut usize,
                  start: i64,end: i64,speed: Rat) {
    if end<=start || speed.n<=0 { return; }
    if *count>0 && segments[*count-1].end==start &&
        cmp(speed,make(segments[*count-1].speed_n,segments[*count-1].speed_d))==0 {
        segments[*count-1].end=end; return;
    }
    segments[*count]=Segment{start,end,speed_n:speed.n,speed_d:speed.d};
    *count+=1;
}
unsafe fn store(out: *mut u8, at: usize, value: i64) {
    let bits=value as u64;
    for b in 0..8 { *out.add(at+b)=(bits>>(8*b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn oa_speed_scaling(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<2 || length>MAX_INPUT { return -1; }
    let count= *input;
    if count<1 || count>MAX_JOBS as i64 || length!=1+3*count as usize { return -1; }
    let n=count as usize;
    let mut release=[0i64;MAX_JOBS]; let mut deadline=[0i64;MAX_JOBS];
    let mut work=[0i64;MAX_JOBS];
    let mut remaining=[integer(0);MAX_JOBS]; let mut completion=[integer(0);MAX_JOBS];
    let mut completed=[false;MAX_JOBS];
    for j in 0..n {
        release[j]=*input.add(1+3*j); deadline[j]=*input.add(2+3*j); work[j]=*input.add(3+3*j);
        if release[j]<0 || release[j]>=deadline[j] || deadline[j]>4 || work[j]<1 || work[j]>4 { return -1; }
    }
    let mut segments=[Segment::default();3]; let mut segment_count=0usize;
    let mut energy=integer(0);
    for now in 0..=4i64 {
        let mut has_arrival=false;
        for j in 0..n { if release[j]==now { remaining[j]=integer(work[j]); has_arrival=true; } }
        if !has_arrival { continue; }
        let mut next_release=5i64;
        for j in 0..n { if release[j]>now && release[j]<next_release { next_release=release[j]; } }
        let mut order=[0usize;MAX_JOBS]; let mut used=0usize;
        for j in 0..n { if remaining[j].n>0 && deadline[j]>now { order[used]=j; used+=1; } }
        for i in 1..used {
            let value=order[i]; let mut k=i;
            while k>0 && (deadline[order[k-1]]>deadline[value] ||
                 (deadline[order[k-1]]==deadline[value] && order[k-1]>value)) {
                order[k]=order[k-1]; k-=1;
            }
            order[k]=value;
        }
        let mut left=now;
        while used>0 {
            let mut prefix=integer(0); let mut best=integer(0); let mut best_count=0usize;
            for k in 1..=used {
                prefix=add(prefix,remaining[order[k-1]]);
                let density=div(prefix,integer(deadline[order[k-1]]-left));
                if best_count==0 || cmp(density,best)>0 { best=density; best_count=k; }
            }
            let right=deadline[order[best_count-1]];
            let stop=if right<next_release {right} else {next_release};
            append_segment(&mut segments,&mut segment_count,left,stop,best);
            energy=add(energy,mul(mul(mul(best,best),best),integer(stop-left)));
            let mut cursor=integer(left); let stop_rat=integer(stop);
            for k in 0..best_count {
                let j=order[k];
                let finish=add(cursor,div(remaining[j],best));
                if cmp(finish,stop_rat)<=0 {
                    completion[j]=finish; completed[j]=true; remaining[j]=integer(0); cursor=finish;
                } else {
                    remaining[j]=sub(remaining[j],mul(best,sub(stop_rat,cursor)));
                    cursor=stop_rat; break;
                }
            }
            if stop<right { break; }
            for k in best_count..used { order[k-best_count]=order[k]; }
            used-=best_count; left=right;
        }
    }
    for j in 0..n { if !completed[j] { return -1; } }
    let mut values=[0i64;19]; let mut fields=0usize;
    values[fields]=segment_count as i64; fields+=1;
    values[fields]=energy.n; fields+=1; values[fields]=energy.d; fields+=1;
    for s in 0..segment_count {
        values[fields]=segments[s].start; fields+=1; values[fields]=segments[s].end; fields+=1;
        values[fields]=segments[s].speed_n; fields+=1; values[fields]=segments[s].speed_d; fields+=1;
    }
    for j in 0..n { values[fields]=completion[j].n; fields+=1; values[fields]=completion[j].d; fields+=1; }
    let bytes=8*fields;
    if output.is_null() || capacity<bytes { return -2; }
    let mut staged=[0u8;MAX_OUTPUT];
    for i in 0..fields { store(staged.as_mut_ptr(),8*i,values[i]); }
    for i in 0..bytes { *output.add(i)=staged[i]; }
    bytes as i64
}
