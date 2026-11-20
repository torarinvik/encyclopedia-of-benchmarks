const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const TABLES: usize = 130;

fn preprocess(pattern: &[i64; TABLES], m: usize, order: &mut [i64; TABLES],
              next: &mut [i64; TABLES], shift: &mut [i64; TABLES]) -> i64 {
    let mut hmax=[0i64;TABLES];
    let mut kmin=[0i64;TABLES];
    let mut prefix=[0i64;TABLES];
    let mut rmin=[0i64;TABLES];
    let (mut i,mut k)=(1i64,1i64);
    while k as usize<=m {
        while pattern[i as usize]==pattern[(i-k) as usize] { i+=1; }
        hmax[k as usize]=i;
        let mut q=k+1;
        while hmax[(q-k) as usize]+k<i { hmax[q as usize]=hmax[(q-k) as usize]+k; q+=1; }
        k=q;
        if k==i+1 { i=k; }
    }
    for x in (1..=m).rev() { if (hmax[x] as usize)<m { kmin[hmax[x] as usize]=x as i64; } }
    let mut r=m as i64;
    for x in (0..m).rev() {
        if hmax[x+1] as usize==m { r=x as i64+1; }
        if kmin[x]==0 { rmin[x]=r; }
    }
    let mut split=-1i64;
    r=m as i64;
    for x in 0..m {
        if kmin[x]==0 { r-=1; order[r as usize]=x as i64; }
        else { split+=1; order[split as usize]=x as i64; }
    }
    let nd=split;
    let nohole_end=nd as usize;
    for x in 0..=nohole_end { shift[x]=kmin[order[x] as usize]; }
    for x in nohole_end+1..m { shift[x]=rmin[order[x] as usize]; }
    shift[m]=rmin[0];
    let mut count=0i64;
    for x in 0..m { prefix[x]=count; if kmin[x]>0 { count+=1; } }
    for x in 0..=nohole_end {
        let position=order[x] as usize;
        next[x]=prefix[(order[x]-kmin[position]) as usize];
    }
    for x in nohole_end+1..m {
        next[x]=prefix[m-rmin[order[x] as usize] as usize];
    }
    next[m]=prefix[m-rmin[order[m-1] as usize] as usize];
    nd
}

fn search(text: &[i64; MAX_TEXT], n: usize, pattern: &[i64; TABLES], m: usize) -> i64 {
    let mut ell=0usize;
    while ell+1<m && pattern[ell+1]==pattern[0] { ell+=1; }
    let (mut matches,mut sum,mut xor_sum)=(0i64,0i64,0i64);
    if ell==m-1 {
        let mut run=0usize;
        for position in 0..n {
            if text[position]==pattern[0] { run+=1; } else { run=0; }
            if run>=m { let start=(position+1-m) as i64; matches+=1; sum+=start; xor_sum^=start; }
        }
        return (matches<<36)|(sum<<12)|xor_sum;
    }
    let (mut order,mut next,mut shift)=([0i64;TABLES],[0i64;TABLES],[0i64;TABLES]);
    let nd=preprocess(pattern,m,&mut order,&mut next,&mut shift);
    if n<m { return 0; }
    let (mut i,mut j,mut last)=(0i64,0i64,-1i64);
    let mut heavy=false;
    while j as usize<=n-m {
        if heavy && i==0 {
            let mut k=last-j+1;
            while (j+k) as usize<n && pattern[0]==text[(j+k) as usize] { k+=1; }
            if k as usize<=ell || (j+k) as usize>=n || pattern[ell+1]!=text[(j+k) as usize] {
                i=0; j+=k+1; last=j-1;
            } else {
                i=1; last=j+k; j=last-(ell as i64+1);
            }
        } else {
            while (i as usize)<m && last<j+order[i as usize] &&
                pattern[order[i as usize] as usize]==text[(j+order[i as usize]) as usize] { i+=1; }
            if i as usize>=m || last>=j+order[i as usize] {
                matches+=1; sum+=j; xor_sum^=j; i=m as i64;
            }
            if i>nd { last=j+m as i64-1; }
            j+=shift[i as usize]; i=next[i as usize];
        }
        heavy=j<=last;
    }
    (matches<<36)|(sum<<12)|xor_sum
}

#[no_mangle]
pub unsafe extern "C" fn galil_giancarlo_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length<2 || length>MAX_INPUT { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let nv=values[0]; let mv=values[1];
    if nv<0 || nv>MAX_TEXT as i64 || mv<1 || mv>MAX_PATTERN as i64 { return -1; }
    let n=nv as usize; let m=mv as usize;
    if length!=2+n+m { return -1; }
    let mut text=[0i64;MAX_TEXT];
    let mut pattern=[0i64;TABLES];
    for i in 0..n { let symbol=values[2+i]; if !(0..=3).contains(&symbol) { return -1; } text[i]=symbol; }
    for i in 0..m { let symbol=values[2+n+i]; if !(0..=3).contains(&symbol) { return -1; } pattern[i]=symbol; }
    pattern[m]=4;
    search(&text,n,&pattern,m)
}
