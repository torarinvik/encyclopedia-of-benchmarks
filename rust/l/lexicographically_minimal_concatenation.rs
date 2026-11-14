// Independent suffix-array/LCP draft; compilation and output are unverified.
use std::cmp::Ordering;

#[derive(Clone, Copy)]
struct Word { start: usize, len: usize }

struct SuffixLcp { rank: Vec<usize>, logs: Vec<usize>, table: Vec<Vec<usize>> }

impl SuffixLcp {
    fn new(text: &[u8]) -> Self {
        let n=text.len();
        let mut sa: Vec<usize>=(0..n).collect();
        let mut classes: Vec<i32>=text.iter().map(|&x| i32::from(x)).collect();
        let mut next=vec![0i32;n];
        let mut step=1;
        while step<n {
            let key=|i: usize| (classes[i], if i+step<n { classes[i+step] } else { -1 });
            sa.sort_unstable_by_key(|&i| key(i));
            next[sa[0]]=0;
            for i in 1..n { next[sa[i]]=next[sa[i-1]]+i32::from(key(sa[i-1])!=key(sa[i])); }
            std::mem::swap(&mut classes,&mut next);
            if classes[sa[n-1]]==n as i32-1 { break; }
            step*=2;
        }
        let mut rank=vec![0usize;n];
        for (i,&suffix) in sa.iter().enumerate() { rank[suffix]=i; }
        let mut lcp=vec![0usize;n];
        let mut shared=0;
        for i in 0..n {
            let r=rank[i];
            if r==0 { shared=0; continue; }
            let j=sa[r-1];
            while i+shared<n && j+shared<n && text[i+shared]==text[j+shared] { shared+=1; }
            lcp[r]=shared;
            shared=shared.saturating_sub(1);
        }
        let mut logs=vec![0usize;n+1];
        for i in 2..=n { logs[i]=logs[i/2]+1; }
        let mut table=vec![lcp];
        let mut width=2;
        while width<=n {
            let half=width/2;
            let previous=table.last().unwrap();
            let row=(0..=n-width).map(|i| previous[i].min(previous[i+half])).collect();
            table.push(row);
            width*=2;
        }
        Self { rank, logs, table }
    }
    fn common(&self, a: usize, b: usize, limit: usize) -> usize {
        if a==b { return limit; }
        let lo=self.rank[a].min(self.rank[b])+1;
        let hi=self.rank[a].max(self.rank[b]);
        let level=self.logs[hi-lo+1];
        limit.min(self.table[level][lo].min(self.table[level][hi-(1<<level)+1]))
    }
}

#[no_mangle]
pub unsafe extern "C" fn lexicographically_minimal_concatenation(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length==0 { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    if !(0..=16384).contains(&values[0]) { return -1; }
    let count=values[0] as usize;
    let mut words=Vec::with_capacity(count);
    let mut text=Vec::new();
    let mut at=1; let mut total=0;
    for _ in 0..count {
        if at>=length || !(1..=65536).contains(&values[at]) { return -1; }
        let size=values[at] as usize; at+=1;
        if size>65536-total || size>length-at { return -1; }
        words.push(Word { start:text.len(), len:size });
        for &value in &values[at..at+size] {
            if !(97..=122).contains(&value) { return -1; }
            text.push(value as u8);
        }
        at+=size; total+=size; text.push(0);
    }
    if at!=length { return -1; }
    if output.is_null() || capacity<total { return -2; }
    if count==0 { return 0; }
    let lcp=SuffixLcp::new(&text);
    let mut order: Vec<usize>=(0..count).collect();
    order.sort_unstable_by(|&a,&b| {
        let left=[words[a],words[b]]; let right=[words[b],words[a]];
        let (mut li,mut ri,mut lp,mut rp)=(0usize,0usize,0usize,0usize);
        while li<2 && ri<2 {
            let limit=(left[li].len-lp).min(right[ri].len-rp);
            let common=lcp.common(left[li].start+lp,right[ri].start+rp,limit);
            if common<limit {
                return text[left[li].start+lp+common].cmp(&text[right[ri].start+rp+common]);
            }
            lp+=common; rp+=common;
            if lp==left[li].len { li+=1; lp=0; }
            if rp==right[ri].len { ri+=1; rp=0; }
        }
        if a==b { Ordering::Equal } else { a.cmp(&b) }
    });
    let mut written=0;
    for index in order {
        let word=words[index];
        for &byte in &text[word.start..word.start+word.len] {
            *output.add(written)=byte; written+=1;
        }
    }
    written as i64
}
