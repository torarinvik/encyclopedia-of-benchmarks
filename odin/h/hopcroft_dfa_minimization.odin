// Independent Hopcroft partition-refinement draft; uncompiled and unrun.
package hopcroft_dfa_minimization
import "core:c"

enqueue :: proc(id: int, queued, queue: []int, tail: ^int) {
    if queued[id]==0 {
        queued[id]=1; queue[tail^]=id; tail^=(tail^+1)%len(queue)
    }
}

@(export)
hopcroft_dfa_minimization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<2 || input[0]<1 || input[0]>4096 || input[1]<1 || input[1]>4 do return -1
    n,k:=int(input[0]),int(input[1])
    if length!=c.size_t(2+n*(k+1)) do return -1
    for s:=0; s<n; s+=1 { if input[2+s]!=0 && input[2+s]!=1 do return -1 }
    for i:=0; i<n*k; i+=1 { if input[2+n+i]<0 || input[2+n+i]>=i64(n) do return -1 }
    nk:=n*k; queue_capacity:=nk+1
    memory:=make([]int,4*nk+9*n+1); defer delete(memory)
    reverse_head:=memory[0:nk]; reverse_next:=memory[nk:2*nk]
    queued:=memory[2*nk:3*nk]; queue:=memory[3*nk:4*nk+1]
    base:=4*nk+1
    block_head:=memory[base:base+n]; block_size:=memory[base+n:base+2*n]
    block_of:=memory[base+2*n:base+3*n]; previous:=memory[base+3*n:base+4*n]
    following:=memory[base+4*n:base+5*n]; selected_head:=memory[base+5*n:base+6*n]
    selected_next:=memory[base+6*n:base+7*n]; selected_count:=memory[base+7*n:base+8*n]
    touched:=memory[base+8*n:base+9*n]
    for i:=0; i<nk; i+=1 { reverse_head[i]=-1 }
    for i:=0; i<n; i+=1 { block_head[i]=-1; selected_head[i]=-1 }
    for state:=0; state<n; state+=1 { for symbol:=0; symbol<k; symbol+=1 {
        edge:=state*k+symbol; dest:=int(input[2+n+edge])
        reverse_next[edge]=reverse_head[symbol*n+dest]; reverse_head[symbol*n+dest]=edge
    } }
    has_zero,has_one:=false,false
    for state:=0; state<n; state+=1 { if input[2+state]==0 { has_zero=true } else { has_one=true } }
    block_count:=0
    if has_zero { block_count+=1 }
    if has_one { block_count+=1 }
    for state:=0; state<n; state+=1 {
        block:=0
        if has_zero && input[2+state]==1 { block=1 }
        block_of[state]=block; previous[state]=-1; following[state]=block_head[block]
        if following[state]!=-1 { previous[following[state]]=state }
        block_head[block]=state; block_size[block]+=1
    }
    qhead,qtail:=0,0
    for block:=0; block<block_count; block+=1 { for symbol:=0; symbol<k; symbol+=1 {
        enqueue(block*k+symbol,queued,queue,&qtail)
    } }
    for qhead!=qtail {
        id:=queue[qhead]; qhead=(qhead+1)%queue_capacity; queued[id]=0
        splitter,symbol:=id/k,id%k; touched_count:=0
        dest:=block_head[splitter]
        for dest!=-1 {
            edge:=reverse_head[symbol*n+dest]
            for edge!=-1 {
                state:=edge/k; block:=block_of[state]
                if selected_count[block]==0 { touched[touched_count]=block; touched_count+=1 }
                selected_count[block]+=1
                selected_next[state]=selected_head[block]; selected_head[block]=state
                edge=reverse_next[edge]
            }
            dest=following[dest]
        }
        for i:=0; i<touched_count; i+=1 {
            block:=touched[i]
            if selected_count[block]==block_size[block] {
                selected_count[block]=0; selected_head[block]=-1; continue
            }
            fresh:=block_count; block_count+=1; state:=selected_head[block]
            for state!=-1 {
                after,prev,next:=selected_next[state],previous[state],following[state]
                if prev==-1 { block_head[block]=next } else { following[prev]=next }
                if next!=-1 { previous[next]=prev }
                block_size[block]-=1
                previous[state]=-1; following[state]=block_head[fresh]
                if following[state]!=-1 { previous[following[state]]=state }
                block_head[fresh]=state; block_size[fresh]+=1; block_of[state]=fresh
                state=after
            }
            selected_head[block]=-1; selected_count[block]=0
            for c:=0; c<k; c+=1 {
                if queued[block*k+c]!=0 { enqueue(fresh*k+c,queued,queue,&qtail) } else {
                    smaller:=block
                    if block_size[fresh]<block_size[block] { smaller=fresh }
                    enqueue(smaller*k+c,queued,queue,&qtail)
                }
            }
        }
    }
    return i64(block_count)
}
