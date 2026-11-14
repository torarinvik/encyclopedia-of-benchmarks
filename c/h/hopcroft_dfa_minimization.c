/* Independent Hopcroft partition-refinement draft; uncompiled and unrun. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

static void enqueue(int id, int *queued, int *queue, int capacity, int *tail) {
    if (!queued[id]) {
        queued[id]=1;
        queue[*tail]=id;
        *tail=(*tail+1)%capacity;
    }
}

int64_t hopcroft_dfa_minimization(const int64_t *input, size_t length) {
    if (!input || length<2 || input[0]<1 || input[0]>4096 || input[1]<1 || input[1]>4) return -1;
    int n=(int)input[0], k=(int)input[1];
    if (length!=2+(size_t)n*(size_t)(k+1)) return -1;
    for (int s=0; s<n; ++s) if (input[2+s]!=0 && input[2+s]!=1) return -1;
    for (int i=0; i<n*k; ++i) if (input[2+n+i]<0 || input[2+n+i]>=n) return -1;
    const int nk=n*k, queue_cap=nk+1;
    int *memory=calloc((size_t)4*nk+(size_t)9*n+1,sizeof(*memory));
    if (!memory) return -1;
    int *reverse_head=memory, *reverse_next=reverse_head+nk;
    int *queued=reverse_next+nk, *queue=queued+nk;
    int *block_head=queue+queue_cap, *block_size=block_head+n;
    int *block_of=block_size+n, *previous=block_of+n, *following=previous+n;
    int *selected_head=following+n, *selected_next=selected_head+n;
    int *selected_count=selected_next+n, *touched=selected_count+n;
    for (int i=0; i<nk; ++i) reverse_head[i]=-1;
    for (int i=0; i<n; ++i) { block_head[i]=-1; selected_head[i]=-1; }
    for (int s=0; s<n; ++s) for (int c=0; c<k; ++c) {
        int edge=s*k+c, dest=(int)input[2+n+edge];
        reverse_next[edge]=reverse_head[c*n+dest]; reverse_head[c*n+dest]=edge;
    }
    int has_zero=0, has_one=0;
    for (int s=0; s<n; ++s) { if (input[2+s]) has_one=1; else has_zero=1; }
    int block_count=has_zero+has_one;
    for (int s=0; s<n; ++s) {
        int b=(input[2+s] && has_zero) ? 1 : 0;
        block_of[s]=b; previous[s]=-1; following[s]=block_head[b];
        if (following[s]!=-1) previous[following[s]]=s;
        block_head[b]=s; ++block_size[b];
    }
    int qhead=0,qtail=0;
    for (int b=0; b<block_count; ++b) for (int c=0; c<k; ++c)
        enqueue(b*k+c,queued,queue,queue_cap,&qtail);
    while (qhead!=qtail) {
        int id=queue[qhead]; qhead=(qhead+1)%queue_cap; queued[id]=0;
        int splitter=id/k, symbol=id%k, touched_count=0;
        for (int dest=block_head[splitter]; dest!=-1; dest=following[dest]) {
            for (int edge=reverse_head[symbol*n+dest]; edge!=-1; edge=reverse_next[edge]) {
                int state=edge/k, b=block_of[state];
                if (selected_count[b]++==0) touched[touched_count++]=b;
                selected_next[state]=selected_head[b]; selected_head[b]=state;
            }
        }
        for (int i=0; i<touched_count; ++i) {
            int b=touched[i];
            if (selected_count[b]==block_size[b]) {
                selected_count[b]=0; selected_head[b]=-1; continue;
            }
            int fresh=block_count++;
            int state=selected_head[b];
            while (state!=-1) {
                int after=selected_next[state], prev=previous[state], next=following[state];
                if (prev==-1) block_head[b]=next; else following[prev]=next;
                if (next!=-1) previous[next]=prev;
                --block_size[b];
                previous[state]=-1; following[state]=block_head[fresh];
                if (following[state]!=-1) previous[following[state]]=state;
                block_head[fresh]=state; ++block_size[fresh]; block_of[state]=fresh;
                state=after;
            }
            selected_head[b]=-1; selected_count[b]=0;
            for (int c=0; c<k; ++c) {
                if (queued[b*k+c]) enqueue(fresh*k+c,queued,queue,queue_cap,&qtail);
                else {
                    int smaller=block_size[fresh]<block_size[b] ? fresh:b;
                    enqueue(smaller*k+c,queued,queue,queue_cap,&qtail);
                }
            }
        }
    }
    free(memory);
    return block_count;
}
