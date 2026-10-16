fn sift(heap: &mut [usize; 64], counts: &[i64; 64], size: usize, root: usize) {
    let mut best = root; let left = root * 2 + 1; let right = left + 1;
    if left < size && counts[heap[left]] > counts[heap[best]] { best = left; }
    if right < size && counts[heap[right]] > counts[heap[best]] { best = right; }
    if best != root { heap.swap(root, best); sift(heap, counts, size, best); }
}

#[no_mangle]
pub extern "C" fn top_kfrequent_words(v: *const i64, n: usize, output: *mut u8, capacity: usize) -> i64 {
    if v.is_null() || n < 2 || n > 1090 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(v, n) };
    if !(0..=64).contains(&v[0]) || !(0..=64).contains(&v[1]) { return -1; }
    let (k, wn) = (v[0] as usize, v[1] as usize);
    let mut words = [[0u8; 16]; 64]; let mut lens = [0usize; 64]; let mut counts = [0i64; 64];
    let mut distinct = 0usize; let mut pos = 2usize;
    for _ in 0..wn {
        if pos >= n || !(1..=16).contains(&v[pos]) { return -1; }
        let len = v[pos] as usize; pos += 1;
        if len > n-pos { return -1; }
        for &c in &v[pos..pos+len] { if !(97..=122).contains(&c) { return -1; } }
        let mut id = 0;
        while id < distinct && !(lens[id] == len && words[id][..len].iter().zip(&v[pos..pos+len]).all(|(&a,&b)| i64::from(a)==b)) { id += 1; }
        if id == distinct { lens[id]=len; for j in 0..len { words[id][j]=v[pos+j] as u8; } distinct+=1; }
        counts[id]+=1; pos+=len;
    }
    if pos != n { return -1; }
    for id in 0..distinct {
        let mut rank = 0i64;
        for other in 0..distinct {
            if words[other][..lens[other]] < words[id][..lens[id]] { rank += 1; }
        }
        counts[id] = counts[id] * 65 + distinct as i64 - rank;
    }
    let mut heap = [0usize;64]; for i in 0..distinct { heap[i]=i; }
    for i in (0..distinct/2).rev() { sift(&mut heap,&counts,distinct,i); }
    let limit=k.min(distinct); let mut temp=[0u8;1089]; let mut at=0;
    for _ in 0..limit { let id=heap[0]; temp[at..at+lens[id]].copy_from_slice(&words[id][..lens[id]]);at+=lens[id];temp[at]=b'\n';at+=1;distinct-=1;heap[0]=heap[distinct];if distinct>0{sift(&mut heap,&counts,distinct,0);} }
    temp[at]=0;at+=1;if output.is_null()||capacity<at{return -2;}unsafe{std::ptr::copy_nonoverlapping(temp.as_ptr(),output,at);}at as i64
}
