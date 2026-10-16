use std::slice;

const MAX_CELLS: usize = 36;
const MAX_WORDS: usize = 32;
const MAX_WORD_LEN: usize = 15;

#[derive(Clone)]
struct Node { children: [i32; 52], word: i32 }
impl Node { fn new() -> Self { Self { children: [-1; 52], word: -1 } } }
fn letter_index(v: i64) -> Option<usize> {
    if (65..=90).contains(&v) { Some((v - 65) as usize) }
    else if (97..=122).contains(&v) { Some((v - 97 + 26) as usize) }
    else { None }
}
fn visit(pos: usize, node: usize, rows: usize, cols: usize, board: &[i64],
         trie: &[Node], visited: &mut [bool], found: &mut [bool]) {
    if visited[pos] { return; }
    let k = match letter_index(board[pos]) { Some(x) => x, None => return };
    let child = trie[node].children[k];
    if child < 0 { return; }
    let child = child as usize;
    visited[pos] = true;
    if trie[child].word >= 0 { found[trie[child].word as usize] = true; }
    let (r,c)=(pos/cols,pos%cols);
    for dr in -1isize..=1 { for dc in -1isize..=1 {
        if dr==0 && dc==0 { continue; }
        let nr=r as isize+dr; let nc=c as isize+dc;
        if nr>=0 && nr<rows as isize && nc>=0 && nc<cols as isize {
            visit(nr as usize*cols+nc as usize,child,rows,cols,board,trie,visited,found);
        }
    }}
    visited[pos]=false;
}

#[no_mangle]
pub unsafe extern "C" fn word_boggle(values: *const i64, length: usize,
                                       output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 3 || length > 2+MAX_CELLS+1+MAX_WORDS*(MAX_WORD_LEN+1) { return -1; }
    let v=slice::from_raw_parts(values,length);
    if !(1..=6).contains(&v[0]) || !(1..=6).contains(&v[1]) { return -1; }
    let rows=v[0] as usize; let cols=v[1] as usize; let cells=rows*cols;
    let mut p=2+cells; if p>=length { return -1; }
    if !(0..=MAX_WORDS as i64).contains(&v[p]) { return -1; }
    let count=v[p] as usize; p+=1;
    let board=&v[2..2+cells];
    if board.iter().any(|&x|letter_index(x).is_none()) { return -1; }
    let mut starts=Vec::with_capacity(count); let mut lens=Vec::with_capacity(count);
    for _ in 0..count {
        if p>=length || !(1..=MAX_WORD_LEN as i64).contains(&v[p]) { return -1; }
        let n=v[p] as usize; if p+1+n>length { return -1; }
        if v[p+1..p+1+n].iter().any(|&x|letter_index(x).is_none()) { return -1; }
        starts.push(p); lens.push(n); p+=1+n;
    }
    if p!=length { return -1; }
    let mut trie=vec![Node::new()];
    for i in 0..count {
        let mut node=0usize;
        for j in 0..lens[i] {
            let k=letter_index(v[starts[i]+1+j]).unwrap();
            let mut child=trie[node].children[k];
            if child<0 { child=trie.len() as i32; trie[node].children[k]=child; trie.push(Node::new()); }
            node=child as usize;
        }
        trie[node].word=i as i32;
    }
    let mut found=vec![false;count]; let mut visited=vec![false;cells];
    for i in 0..cells { visit(i,0,rows,cols,board,&trie,&mut visited,&mut found); }
    let mut order:Vec<usize>=(0..count).collect();
    order.sort_by(|&a,&b|v[starts[a]+1..starts[a]+1+lens[a]].cmp(&v[starts[b]+1..starts[b]+1+lens[b]]));
    let mut result=Vec::new(); let mut prior:Option<Vec<i64>>=None;
    for i in order { if found[i] {
        let word=v[starts[i]+1..starts[i]+1+lens[i]].to_vec();
        if prior.as_ref()!=Some(&word) { for c in &word { result.push(*c as u8); } result.push(0); prior=Some(word); }
    }}
    if result.len()>capacity { return -2; }
    if !result.is_empty() && output.is_null() { return -1; }
    if !result.is_empty() { std::ptr::copy_nonoverlapping(result.as_ptr(),output,result.len()); }
    result.len() as i64
}
