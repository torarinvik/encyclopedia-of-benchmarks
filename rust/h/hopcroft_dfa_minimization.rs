// Independent Hopcroft partition-refinement draft; uncompiled and unrun.
use std::collections::VecDeque;

fn enqueue(queue: &mut VecDeque<(usize, usize)>, queued: &mut [bool],
           block: usize, symbol: usize, alphabet: usize) {
    let id=block*alphabet+symbol;
    if !queued[id] { queued[id]=true; queue.push_back((block,symbol)); }
}

#[no_mangle]
pub unsafe extern "C" fn hopcroft_dfa_minimization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length<2 { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    if !(1..=4096).contains(&values[0]) || !(1..=4).contains(&values[1]) { return -1; }
    let n=values[0] as usize; let k=values[1] as usize;
    if length!=2+n*(1+k) || values[2..2+n].iter().any(|&x| x!=0 && x!=1)
        || values[2+n..].iter().any(|&x| x<0 || x>=n as i64) { return -1; }
    let mut head=vec![usize::MAX;k*n]; let mut next=vec![usize::MAX;k*n];
    for state in 0..n { for symbol in 0..k {
        let edge=state*k+symbol; let dest=values[2+n+edge] as usize;
        next[edge]=head[symbol*n+dest]; head[symbol*n+dest]=edge;
    } }
    let mut blocks=vec![Vec::new(),Vec::new()];
    for state in 0..n { blocks[values[2+state] as usize].push(state); }
    blocks.retain(|block| !block.is_empty());
    let mut block_of=vec![0usize;n]; let mut position=vec![0usize;n];
    for (b,block) in blocks.iter().enumerate() {
        for (i,&state) in block.iter().enumerate() { block_of[state]=b; position[state]=i; }
    }
    let mut work=VecDeque::new(); let mut queued=vec![false;n*k];
    for b in 0..blocks.len() { for c in 0..k { enqueue(&mut work,&mut queued,b,c,k); } }
    let mut marked=vec![0usize;n]; let mut epoch=0usize;
    let mut selected: Vec<Vec<usize>>=(0..n).map(|_| Vec::new()).collect();
    let mut touched=Vec::new();
    while let Some((splitter,symbol))=work.pop_front() {
        queued[splitter*k+symbol]=false;
        epoch+=1; touched.clear();
        for &dest in &blocks[splitter] {
            let mut edge=head[symbol*n+dest];
            while edge!=usize::MAX {
                let state=edge/k;
                if marked[state]!=epoch {
                    marked[state]=epoch;
                    let b=block_of[state];
                    if selected[b].is_empty() { touched.push(b); }
                    selected[b].push(state);
                }
                edge=next[edge];
            }
        }
        for &b in &touched {
            if selected[b].len()==blocks[b].len() { selected[b]=Vec::new(); continue; }
            let fresh=blocks.len(); blocks.push(Vec::new());
            for &state in &selected[b] {
                let pos=position[state];
                let moved=blocks[b].swap_remove(pos);
                if pos<blocks[b].len() { position[blocks[b][pos]]=pos; }
                position[moved]=blocks[fresh].len();
                blocks[fresh].push(moved); block_of[moved]=fresh;
            }
            if blocks[b].len()*2<blocks[b].capacity() { blocks[b].shrink_to_fit(); }
            selected[b]=Vec::new();
            for c in 0..k {
                if queued[b*k+c] { enqueue(&mut work,&mut queued,fresh,c,k); }
                else {
                    let smaller=if blocks[fresh].len()<blocks[b].len() { fresh } else { b };
                    enqueue(&mut work,&mut queued,smaller,c,k);
                }
            }
        }
    }
    blocks.len() as i64
}
