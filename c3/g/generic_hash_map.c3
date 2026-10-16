module generic_hash_map;
fn ulong map_hash_value(ulong h, long value) {
    ulong bits = (ulong)value;
    for (int i=0; i<8; i++) h = (h ^ ((bits >> (8*i)) & 255)) * 0x100000001b3;
    return h;
}
fn long generic_hash_map(long* a, usz n) @export("generic_hash_map") {
    if (a == null || n < 1 || n > 385 || a[0] < 0 || a[0] > 128 || n != 1 + 3*(usz)a[0]) return -1;
    long[64] keys; long[64] vals; int[64] next; int[128] head; bool[64] active;
    for (int i=0; i<64; i++) { next[i] = -1; active[i] = false; }
    for (int i=0; i<128; i++) head[i] = -1;
    int size = 0; int buckets = 16; ulong h = 0xcbf29ce484222325;
    for (int oi=0; oi<(int)a[0]; oi++) {
        long op = a[1+3*oi]; long key = a[2+3*oi]; long value = a[3+3*oi];
        if (key < 0 || key > 1000000) return -1;
        int b = (int)(key % buckets); int found = -1;
        for (int j=head[b]; j>=0; j=next[j]) if (keys[j] == key) { found=j; break; }
        if (op == 0) {
            if (value < -1000000 || value > 1000000) return -1;
            if (found >= 0) { vals[found] = value; }
            else {
                if (size >= 64) return -1;
                int j=0; while (active[j]) j++;
                active[j]=true; keys[j]=key; vals[j]=value; next[j]=head[b]; head[b]=j; size++;
                if (size*4 > buckets*3 && buckets < 128) {
                    buckets *= 2; for (int i=0;i<128;i++) head[i]=-1;
                    for (int q=0;q<64;q++) if (active[q]) { b=(int)(keys[q]%buckets); next[q]=head[b]; head[b]=q; }
                }
            }
        } else if (op == 1 || op == 3) {
            if (value != 0) return -1;
            long observed = op == 1 ? (found >= 0 ? vals[found] : -9223372036854775807 - 1) : (found >= 0 ? 1 : 0);
            h=map_hash_value(h,observed);
        } else if (op == 2) {
            if (value != 0) return -1;
            if (found >= 0) { int prev=-1; for (int j=head[b];j>=0;j=next[j]) { if(j==found){if(prev<0){head[b]=next[j];}else{next[prev]=next[j];}break;}prev=j;} active[found]=false; size--; }
        } else if (op == 4) { if(key!=0||value!=0)return -1;h=map_hash_value(h,size); }
        else { return -1; }
    }
    h=map_hash_value(h,size); bool[64] used; for(int i=0;i<64;i++)used[i]=false;
    for(int rank=0;rank<size;rank++){int best=-1;for(int i=0;i<64;i++)if(active[i]&&!used[i]&&(best<0||keys[i]<keys[best]))best=i;used[best]=true;h=map_hash_value(map_hash_value(h,keys[best]),vals[best]);}
    return (long)h;
}
