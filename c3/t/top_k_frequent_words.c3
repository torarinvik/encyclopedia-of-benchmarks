module top_k_frequent_words;

fn bool greater_count(long* heap, long* counts, usz a, usz b) { return counts[heap[a]] > counts[heap[b]]; }
fn void sift_down(long* heap, long* counts, usz size, usz root) {
    usz best = root, left = root * 2 + 1, right = left + 1;
    if (left < size && greater_count(heap, counts, left, best)) best = left;
    if (right < size && greater_count(heap, counts, right, best)) best = right;
    if (best != root) { long t = heap[root]; heap[root] = heap[best]; heap[best] = t; sift_down(heap, counts, size, best); }
}

fn long top_k_frequent_words(long* v, usz n, char* output, usz output_capacity) @export("top_k_frequent_words") {
    if (v == null || n < 2 || n > 1090 || v[0] < 0 || v[0] > 64 || v[1] < 0 || v[1] > 64) return -1;
    long lens[64] = {}, counts[64] = {}, words[64][16] = {}, heap[64] = {}, temp[1089] = {};
    usz k = (usz)v[0], wn = (usz)v[1], distinct = 0, pos = 2;
    for (usz w = 0; w < wn; w++) {
        if (pos >= n || v[pos] < 1 || v[pos] > 16 || v[pos] > (long)(n-pos-1)) return -1;
        usz len = (usz)v[pos++]; for (usz j=0;j<len;j++) if(v[pos+j]<'a'||v[pos+j]>'z') return -1;
        usz id=0; for(;id<distinct;id++) if((usz)lens[id]==len){usz j=0;while(j<len&&words[id][j]==v[pos+j])j++;if(j==len)break;}
        if(id==distinct){lens[id]=(long)len;for(usz j=0;j<len;j++)words[id][j]=v[pos+j];distinct++;} counts[id]++;pos+=len;
    }
    if(pos!=n)return -1;for(usz i=0;i<distinct;i++)heap[i]=(long)i;
    usz i=distinct/2;while(i>0){i--;sift_down(heap,counts,distinct,i);}
    usz limit=k<distinct?k:distinct, at=0;
    for(usz r=0;r<limit;r++){usz id=(usz)heap[0];for(usz j=0;j<(usz)lens[id];j++)temp[at++]=words[id][j];temp[at++]='\n';heap[0]=heap[--distinct];if(distinct>0)sift_down(heap,counts,distinct,0);}
    temp[at++]=0;if(output==null||output_capacity<at)return -2;for(usz j=0;j<at;j++)output[j]=temp[j];return (long)at;
}
