module dynamic_range_majority;

struct Summary { long value; int count; }
fn Summary merge(Summary a, Summary b) {
    if (a.count == 0) return b;
    if (b.count == 0) return a;
    if (a.value == b.value) return {a.value,a.count+b.count};
    if (a.count >= b.count) return {a.value,a.count-b.count};
    return {b.value,b.count-a.count};
}
fn int slot(long value, long* names, int* size) {
    for (int i=0; i<*size; i++) if (names[i] == value) return i;
    int result = *size; names[result] = value; (*size)++; return result;
}
fn ulong prefix(int p) { return p == 64 ? ~0UL : (1UL << p)-1; }

fn long dynamic_range_majority(long* input, usz length, uchar* output, usz capacity)
        @export("dynamic_range_majority") {
    if (input == null || length < 2 || length > 258) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64) return -1;
    int n = (int)input[0], q = (int)input[1], queries = 0;
    if (length != (usz)(2+n+3*q)) return -1;
    for (int i=0; i<n; i++) if (input[2+i] < 0 || input[2+i] > 1000000000) return -1;
    for (int i=0; i<q; i++) {
        int b=2+n+3*i;
        if (input[b] == 0) {
            if (input[b+1] < 0 || input[b+1] >= n || input[b+2] < 0 || input[b+2] > 1000000000) return -1;
        } else if (input[b] == 1) {
            if (input[b+1] < 0 || input[b+1] >= input[b+2] || input[b+2] > n) return -1;
            queries++;
        } else return -1;
    }
    if (queries == 0) return -1;
    if (output == null || capacity < (usz)(8*queries)) return -2;
    Summary[128] tree = {};
    long[128] names = {};
    long[64] data = {};
    ulong[128] masks = {};
    int distinct = 0;
    for (int i=0; i<n; i++) {
        data[i] = input[2+i]; tree[64+i] = {data[i],1};
        int s=slot(data[i],&names[0],&distinct); masks[s] |= 1UL << i;
    }
    for (int i=63; i>0; i--) tree[i] = merge(tree[2*i],tree[2*i+1]);
    int written=0;
    for (int i=0; i<q; i++) {
        int b=2+n+3*i;
        if (input[b] == 0) {
            int p=(int)input[b+1]; long value=input[b+2];
            int old=slot(data[p],&names[0],&distinct), fresh=slot(value,&names[0],&distinct);
            masks[old] &= ~(1UL << p); masks[fresh] |= 1UL << p;
            data[p]=value; int node=64+p; tree[node]={value,1};
            while (node>1) { node/=2; tree[node]=merge(tree[2*node],tree[2*node+1]); }
        } else {
            int lo=(int)input[b+1], hi=(int)input[b+2], l=lo+64, r=hi+64;
            Summary a={}, z={};
            while (l<r) {
                if ((l & 1) != 0) a=merge(a,tree[l++]);
                if ((r & 1) != 0) z=merge(tree[--r],z);
                l/=2; r/=2;
            }
            Summary candidate=merge(a,z); long answer=-1;
            if (candidate.count != 0) {
                int s=slot(candidate.value,&names[0],&distinct), count=0;
                ulong bits=masks[s] & (prefix(hi)^prefix(lo));
                while (bits != 0) { bits &= bits-1; count++; }
                if (2*count>hi-lo) answer=candidate.value;
            }
            ulong encoded=(ulong)answer;
            for (int byte=0; byte<8; byte++) output[8*written+byte]=(uchar)(encoded >> (8*byte));
            written++;
        }
    }
    return 8*written;
}
