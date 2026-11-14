// Independent Hopcroft partition-refinement draft; uncompiled and unrun.
module hopcroft_dfa_minimization

fn hdm_enqueue(id int, mut queued []int, mut queue []int, mut tail int) {
    if queued[id]==0 {
        queued[id]=1
        queue[tail]=id
        tail=(tail+1)%queue.len
    }
}

@[export: 'hopcroft_dfa_minimization']
pub fn hopcroft_dfa_minimization(input &i64, length usize) i64 {
    if length<2 { return -1 }
    unsafe {
        if input==nil || input[0]<1 || input[0]>4096 || input[1]<1 || input[1]>4 { return -1 }
        n:=int(input[0]); k:=int(input[1])
        if length!=usize(2+n*(k+1)) { return -1 }
        for s in 0 .. n { if input[2+s]!=0 && input[2+s]!=1 { return -1 } }
        for i in 0 .. n*k { if input[2+n+i]<0 || input[2+n+i]>=i64(n) { return -1 } }
        nk:=n*k
        mut reverse_head:=[]int{len:nk,init:-1}
        mut reverse_next:=[]int{len:nk}
        mut queued:=[]int{len:nk}
        mut queue:=[]int{len:nk+1}
        mut block_head:=[]int{len:n,init:-1}
        mut block_size:=[]int{len:n}
        mut block_of:=[]int{len:n}
        mut previous:=[]int{len:n}
        mut following:=[]int{len:n}
        mut selected_head:=[]int{len:n,init:-1}
        mut selected_next:=[]int{len:n}
        mut selected_count:=[]int{len:n}
        mut touched:=[]int{len:n}
        for state in 0 .. n { for symbol in 0 .. k {
            edge:=state*k+symbol; dest:=int(input[2+n+edge])
            reverse_next[edge]=reverse_head[symbol*n+dest]
            reverse_head[symbol*n+dest]=edge
        } }
        mut has_zero:=false; mut has_one:=false
        for state in 0 .. n { if input[2+state]==0 { has_zero=true } else { has_one=true } }
        mut block_count:=0
        if has_zero { block_count++ }
        if has_one { block_count++ }
        for state in 0 .. n {
            block:=if has_zero && input[2+state]==1 { 1 } else { 0 }
            block_of[state]=block; previous[state]=-1; following[state]=block_head[block]
            if following[state]!=-1 { previous[following[state]]=state }
            block_head[block]=state; block_size[block]++
        }
        mut qhead:=0; mut qtail:=0
        for block in 0 .. block_count { for symbol in 0 .. k {
            hdm_enqueue(block*k+symbol,mut queued,mut queue,mut qtail)
        } }
        for qhead!=qtail {
            id:=queue[qhead]; qhead=(qhead+1)%queue.len; queued[id]=0
            splitter:=id/k; symbol:=id%k
            mut touched_count:=0
            mut dest:=block_head[splitter]
            for dest!=-1 {
                mut edge:=reverse_head[symbol*n+dest]
                for edge!=-1 {
                    state:=edge/k; block:=block_of[state]
                    if selected_count[block]==0 { touched[touched_count]=block; touched_count++ }
                    selected_count[block]++
                    selected_next[state]=selected_head[block]; selected_head[block]=state
                    edge=reverse_next[edge]
                }
                dest=following[dest]
            }
            for i in 0 .. touched_count {
                block:=touched[i]
                if selected_count[block]==block_size[block] {
                    selected_count[block]=0; selected_head[block]=-1; continue
                }
                fresh:=block_count; block_count++
                mut state:=selected_head[block]
                for state!=-1 {
                    after:=selected_next[state]; prev:=previous[state]; next:=following[state]
                    if prev==-1 { block_head[block]=next } else { following[prev]=next }
                    if next!=-1 { previous[next]=prev }
                    block_size[block]--
                    previous[state]=-1; following[state]=block_head[fresh]
                    if following[state]!=-1 { previous[following[state]]=state }
                    block_head[fresh]=state; block_size[fresh]++; block_of[state]=fresh
                    state=after
                }
                selected_head[block]=-1; selected_count[block]=0
                for symbol_id in 0 .. k {
                    if queued[block*k+symbol_id]!=0 {
                        hdm_enqueue(fresh*k+symbol_id,mut queued,mut queue,mut qtail)
                    } else {
                        smaller:=if block_size[fresh]<block_size[block] { fresh } else { block }
                        hdm_enqueue(smaller*k+symbol_id,mut queued,mut queue,mut qtail)
                    }
                }
            }
        }
        return i64(block_count)
    }
}
