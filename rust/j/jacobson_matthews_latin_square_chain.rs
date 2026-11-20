const MAX_N: usize = 4;
const MAX_CELLS: usize = 64;
const MAX_MOVES: usize = 48;
const MAX_WORDS: usize = 66;

#[derive(Clone, Copy, Default)]
struct Move { i: usize, j: usize, k: usize, ip: usize, jp: usize, kp: usize }

fn at(n: usize, i: usize, j: usize, k: usize) -> usize { (i * n + j) * n + k }

fn select_move(t: &[i64; MAX_CELLS], n: usize, choice: usize) -> Option<Move> {
    let mut moves = [Move::default(); MAX_MOVES];
    let (mut defects, mut pi, mut pj, mut pk, mut count) = (0, 0, 0, 0, 0);
    for i in 0..n { for j in 0..n { for k in 0..n {
        if t[at(n,i,j,k)] == -1 { defects += 1; pi=i; pj=j; pk=k; }
    }}}
    if defects > 1 { return None; }
    if defects == 1 {
        for ip in 0..n { for jp in 0..n { for kp in 0..n {
            if ip!=pi && jp!=pj && kp!=pk && t[at(n,pi,pj,kp)]==1 &&
                t[at(n,pi,jp,pk)]==1 && t[at(n,ip,pj,pk)]==1 {
                moves[count]=Move{i:pi,j:pj,k:pk,ip,jp,kp}; count+=1;
            }
        }}}
        if count != 8 { return None; }
    } else {
        for i in 0..n { for j in 0..n { for k in 0..n {
            if t[at(n,i,j,k)] != 0 { continue; }
            let (mut ip,mut jp,mut kp)=(n,n,n);
            for x in 0..n { if t[at(n,x,j,k)]==1 { ip=x; } }
            for x in 0..n { if t[at(n,i,x,k)]==1 { jp=x; } }
            for x in 0..n { if t[at(n,i,j,x)]==1 { kp=x; } }
            if ip==n || jp==n || kp==n { return None; }
            moves[count]=Move{i,j,k,ip,jp,kp}; count+=1;
        }}}
        if count != n*n*n-n*n { return None; }
    }
    if choice >= count { None } else { Some(moves[choice]) }
}

fn apply_choice(t: &mut [i64; MAX_CELLS], n: usize, choice: usize) -> bool {
    let Some(m)=select_move(t,n,choice) else { return false; };
    t[at(n,m.i,m.j,m.k)]+=1; t[at(n,m.ip,m.jp,m.k)]+=1;
    t[at(n,m.ip,m.j,m.kp)]+=1; t[at(n,m.i,m.jp,m.kp)]+=1;
    t[at(n,m.ip,m.j,m.k)]-=1; t[at(n,m.i,m.jp,m.k)]-=1;
    t[at(n,m.i,m.j,m.kp)]-=1; t[at(n,m.ip,m.jp,m.kp)]-=1;
    true
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset+8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn jacobson_matthews_latin_square_chain(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<2 || length>14 { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let nv=values[0]; let sv=values[1];
    if nv<2 || nv>MAX_N as i64 || sv<0 || sv>12 || length!=2+sv as usize { return -1; }
    let n=nv as usize; let steps=sv as usize;
    let mut tensor=[0i64;MAX_CELLS];
    for i in 0..n { for j in 0..n { tensor[at(n,i,j,(i+j)%n)]=1; } }
    for step in 0..steps {
        let choice=values[2+step];
        if choice<0 || choice>=MAX_MOVES as i64 || !apply_choice(&mut tensor,n,choice as usize) { return -1; }
    }
    let count=2+n*n*n; let bytes=count*8;
    if output.is_null() || capacity<bytes { return -2; }
    let mut words=[0i64;MAX_WORDS]; words[0]=nv; words[1]=sv;
    words[2..count].copy_from_slice(&tensor[..n*n*n]);
    let out=std::slice::from_raw_parts_mut(output,bytes);
    for i in 0..count { write_i64_le(out,i*8,words[i]); }
    bytes as i64
}
