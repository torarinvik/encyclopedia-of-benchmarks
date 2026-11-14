// Independent Hopcroft partition-refinement draft; uncompiled and unrun.
const std=@import("std");
const none=std.math.maxInt(usize);

fn enqueue(id: usize, queued: []usize, queue: []usize, tail: *usize) void {
    if (queued[id]==0) {
        queued[id]=1;
        queue[tail.*]=id;
        tail.*=(tail.*+1)%queue.len;
    }
}

export fn hopcroft_dfa_minimization(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt==null or length<2) return -1;
    const input=input_opt.?[0..length];
    if (input[0]<1 or input[0]>4096 or input[1]<1 or input[1]>4) return -1;
    const n: usize=@intCast(input[0]); const k: usize=@intCast(input[1]);
    if (length!=2+n*(k+1)) return -1;
    for (0..n) |s| if (input[2+s]!=0 and input[2+s]!=1) return -1;
    for (0..n*k) |i| if (input[2+n+i]<0 or input[2+n+i]>=input[0]) return -1;
    const nk=n*k; const queue_cap=nk+1;
    const allocator=std.heap.page_allocator;
    const memory=allocator.alloc(usize,4*nk+9*n+1) catch return -1;
    defer allocator.free(memory);
    @memset(memory,0);
    const reverse_head=memory[0..nk]; const reverse_next=memory[nk..2*nk];
    const queued=memory[2*nk..3*nk]; const queue=memory[3*nk..4*nk+1];
    const base=4*nk+1;
    const block_head=memory[base..base+n]; const block_size=memory[base+n..base+2*n];
    const block_of=memory[base+2*n..base+3*n]; const previous=memory[base+3*n..base+4*n];
    const following=memory[base+4*n..base+5*n]; const selected_head=memory[base+5*n..base+6*n];
    const selected_next=memory[base+6*n..base+7*n]; const selected_count=memory[base+7*n..base+8*n];
    const touched=memory[base+8*n..base+9*n];
    @memset(reverse_head,none); @memset(block_head,none); @memset(selected_head,none);
    for (0..n) |state| for (0..k) |symbol| {
        const edge=state*k+symbol; const dest: usize=@intCast(input[2+n+edge]);
        reverse_next[edge]=reverse_head[symbol*n+dest]; reverse_head[symbol*n+dest]=edge;
    };
    var has_zero=false; var has_one=false;
    for (0..n) |state| {
        if (input[2+state]==0) has_zero=true else has_one=true;
    }
    var block_count: usize=@as(usize,@intFromBool(has_zero))+@as(usize,@intFromBool(has_one));
    for (0..n) |state| {
        const block: usize=if (has_zero and input[2+state]==1) 1 else 0;
        block_of[state]=block; previous[state]=none; following[state]=block_head[block];
        if (following[state]!=none) previous[following[state]]=state;
        block_head[block]=state; block_size[block]+=1;
    }
    var qhead: usize=0; var qtail: usize=0;
    for (0..block_count) |block| for (0..k) |symbol| enqueue(block*k+symbol,queued,queue,&qtail);
    while (qhead!=qtail) {
        const id=queue[qhead]; qhead=(qhead+1)%queue_cap; queued[id]=0;
        const splitter=id/k; const symbol=id%k;
        var touched_count: usize=0;
        var dest=block_head[splitter];
        while (dest!=none) {
            var edge=reverse_head[symbol*n+dest];
            while (edge!=none) {
                const state=edge/k; const block=block_of[state];
                if (selected_count[block]==0) { touched[touched_count]=block; touched_count+=1; }
                selected_count[block]+=1;
                selected_next[state]=selected_head[block]; selected_head[block]=state;
                edge=reverse_next[edge];
            }
            dest=following[dest];
        }
        for (touched[0..touched_count]) |block| {
            if (selected_count[block]==block_size[block]) {
                selected_count[block]=0; selected_head[block]=none; continue;
            }
            const fresh=block_count; block_count+=1;
            var state=selected_head[block];
            while (state!=none) {
                const after=selected_next[state]; const prev=previous[state]; const next=following[state];
                if (prev==none) block_head[block]=next else following[prev]=next;
                if (next!=none) previous[next]=prev;
                block_size[block]-=1;
                previous[state]=none; following[state]=block_head[fresh];
                if (following[state]!=none) previous[following[state]]=state;
                block_head[fresh]=state; block_size[fresh]+=1; block_of[state]=fresh;
                state=after;
            }
            selected_head[block]=none; selected_count[block]=0;
            for (0..k) |symbol_id| {
                if (queued[block*k+symbol_id]!=0) enqueue(fresh*k+symbol_id,queued,queue,&qtail)
                else {
                    const smaller=if (block_size[fresh]<block_size[block]) fresh else block;
                    enqueue(smaller*k+symbol_id,queued,queue,&qtail);
                }
            }
        }
    }
    return @intCast(block_count);
}
