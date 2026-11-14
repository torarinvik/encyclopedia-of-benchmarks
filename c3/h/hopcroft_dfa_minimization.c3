// Independent Hopcroft partition-refinement draft; uncompiled and unrun.
module hopcroft_dfa_minimization;
extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

fn void hdm_enqueue(int id, int* queued, int* queue, int capacity, int* tail) {
    if (queued[id]==0) {
        queued[id]=1;
        queue[*tail]=id;
        *tail=(*tail+1)%capacity;
    }
}

fn long hopcroft_dfa_minimization(long* input, usz length) @export("hopcroft_dfa_minimization") {
    if (input==null || length<2 || input[0]<1 || input[0]>4096 || input[1]<1 || input[1]>4) return -1;
    int n=(int)input[0], k=(int)input[1];
    if (length!=2+(usz)n*(usz)(k+1)) return -1;
    for (int s=0; s<n; s++) if (input[2+s]!=0 && input[2+s]!=1) return -1;
    for (int i=0; i<n*k; i++) if (input[2+n+i]<0 || input[2+n+i]>=n) return -1;
    int nk=n*k, queue_capacity=nk+1;
    int* memory=(int*)calloc((usz)(4*nk+9*n+1),sizeof(int));
    if (memory==null) return -1;
    int* reverse_head=memory; int* reverse_next=reverse_head+nk;
    int* queued=reverse_next+nk; int* queue=queued+nk;
    int* block_head=queue+queue_capacity; int* block_size=block_head+n;
    int* block_of=block_size+n; int* previous=block_of+n; int* following=previous+n;
    int* selected_head=following+n; int* selected_next=selected_head+n;
    int* selected_count=selected_next+n; int* touched=selected_count+n;
    for (int i=0; i<nk; i++) reverse_head[i]=-1;
    for (int i=0; i<n; i++) { block_head[i]=-1; selected_head[i]=-1; }
    for (int state=0; state<n; state++) for (int symbol=0; symbol<k; symbol++) {
        int edge=state*k+symbol, dest=(int)input[2+n+edge];
        reverse_next[edge]=reverse_head[symbol*n+dest]; reverse_head[symbol*n+dest]=edge;
    }
    bool has_zero=false, has_one=false;
    for (int state=0; state<n; state++) {
        if (input[2+state]==0) has_zero=true; else has_one=true;
    }
    int block_count=(has_zero ? 1 : 0)+(has_one ? 1 : 0);
    for (int state=0; state<n; state++) {
        int block=has_zero && input[2+state]==1 ? 1 : 0;
        block_of[state]=block; previous[state]=-1; following[state]=block_head[block];
        if (following[state]!=-1) previous[following[state]]=state;
        block_head[block]=state; block_size[block]++;
    }
    int qhead=0, qtail=0;
    for (int block=0; block<block_count; block++) for (int symbol=0; symbol<k; symbol++)
        hdm_enqueue(block*k+symbol,queued,queue,queue_capacity,&qtail);
    while (qhead!=qtail) {
        int id=queue[qhead]; qhead=(qhead+1)%queue_capacity; queued[id]=0;
        int splitter=id/k, symbol=id%k, touched_count=0;
        for (int dest=block_head[splitter]; dest!=-1; dest=following[dest]) {
            for (int edge=reverse_head[symbol*n+dest]; edge!=-1; edge=reverse_next[edge]) {
                int state=edge/k, block=block_of[state];
                if (selected_count[block]++==0) touched[touched_count++]=block;
                selected_next[state]=selected_head[block]; selected_head[block]=state;
            }
        }
        for (int i=0; i<touched_count; i++) {
            int block=touched[i];
            if (selected_count[block]==block_size[block]) {
                selected_count[block]=0; selected_head[block]=-1; continue;
            }
            int fresh=block_count++, state=selected_head[block];
            while (state!=-1) {
                int after=selected_next[state], prev=previous[state], next=following[state];
                if (prev==-1) block_head[block]=next; else following[prev]=next;
                if (next!=-1) previous[next]=prev;
                block_size[block]--;
                previous[state]=-1; following[state]=block_head[fresh];
                if (following[state]!=-1) previous[following[state]]=state;
                block_head[fresh]=state; block_size[fresh]++; block_of[state]=fresh;
                state=after;
            }
            selected_head[block]=-1; selected_count[block]=0;
            for (int c=0; c<k; c++) {
                if (queued[block*k+c]!=0) hdm_enqueue(fresh*k+c,queued,queue,queue_capacity,&qtail);
                else {
                    int smaller=block_size[fresh]<block_size[block] ? fresh : block;
                    hdm_enqueue(smaller*k+c,queued,queue,queue_capacity,&qtail);
                }
            }
        }
    }
    free(memory);
    return (long)block_count;
}
