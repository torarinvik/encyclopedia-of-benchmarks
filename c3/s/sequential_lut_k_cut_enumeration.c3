module sequential_lut_k_cut_enumeration;

const int MAX_N = 3;
const int MAX_M = 3;
const int MAX_CUTS = 45;

fn int cut_popcount(ulong value) {
    int count = 0;
    while (value != 0) { value &= value - 1; count++; }
    return count;
}
fn bool cut_shift(ulong cut, int n, int delay, ulong* result) {
    result[0] = 0;
    for (int bit = 0; bit < 3*n; bit++) {
        if ((cut & (1UL << bit)) != 0) {
            int next_delay = bit % 3 + delay;
            if (next_delay > 2) return false;
            result[0] |= 1UL << (3*(bit/3) + next_delay);
        }
    }
    return true;
}
fn void cut_add(ulong* cuts, int* counts, int node, ulong mask, int k) {
    if (cut_popcount(mask) > k) return;
    int base = node * MAX_CUTS;
    for (int i = 0; i < counts[node]; i++) if (cuts[base+i] == mask) return;
    if (counts[node] < MAX_CUTS) { cuts[base+counts[node]] = mask; counts[node]++; }
}
fn void cut_put_i64(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[word*8+byte] = (char)((bits >> (byte*8)) & 255);
}

fn long sequential_lut_k_cut_enumeration(long* input, usz input_length,
        char* output, usz output_capacity) @export("sequential_lut_k_cut_enumeration") {
    if (input == null || input_length < 3 || input_length > 12) return -1;
    long n0=input[0], k0=input[1], m0=input[2];
    if (n0<1 || n0>3 || k0<1 || k0>2 || m0<0 || m0>3 || input_length != (usz)(3+3*m0)) return -1;
    int n=(int)n0, k=(int)k0, m=(int)m0;
    int[MAX_M] eu={0}, ev={0}, ed={0};
    for (int e=0;e<m;e++) {
        long u=input[3+3*e], v=input[4+3*e], d=input[5+3*e];
        if (u<0 || v<=u || v>=n0 || (d!=0 && d!=1)) return -1;
        for (int j=0;j<e;j++) if (eu[j]==(int)u && ev[j]==(int)v && ed[j]==(int)d) return -1;
        eu[e]=(int)u;ev[e]=(int)v;ed[e]=(int)d;
    }
    int[MAX_N*MAX_M] in_u={0}, in_d={0}; int[MAX_N] degree={0};
    for (int e=0;e<m;e++) { int v=ev[e], slot=degree[v]; in_u[v*MAX_M+slot]=eu[e];in_d[v*MAX_M+slot]=ed[e];degree[v]++; }
    ulong[MAX_N*MAX_CUTS] cuts={0}; int[MAX_N] counts={0};
    for (int v=0;v<n;v++) {
        cut_add(&cuts[0],&counts[0],v,1UL << (3*v),k);
        if (degree[v] > 0) {
            int c0=counts[in_u[v*MAX_M]],c1=1,c2=1;
            if (degree[v]>1) c1=counts[in_u[v*MAX_M+1]];
            if (degree[v]>2) c2=counts[in_u[v*MAX_M+2]];
            for (int a=0;a<c0;a++) for (int b=0;b<c1;b++) for (int c=0;c<c2;c++) {
                ulong merged=0,shifted=0;
                int u=in_u[v*MAX_M];
                if (!cut_shift(cuts[u*MAX_CUTS+a],n,in_d[v*MAX_M],&shifted)) return -1;
                merged |= shifted;
                if (degree[v]>1) { u=in_u[v*MAX_M+1];if(!cut_shift(cuts[u*MAX_CUTS+b],n,in_d[v*MAX_M+1],&shifted))return -1;merged|=shifted; }
                if (degree[v]>2) { u=in_u[v*MAX_M+2];if(!cut_shift(cuts[u*MAX_CUTS+c],n,in_d[v*MAX_M+2],&shifted))return -1;merged|=shifted; }
                cut_add(&cuts[0],&counts[0],v,merged,k);
            }
        }
        int base=v*MAX_CUTS;
        for (int i=1;i<counts[v];i++) { ulong value=cuts[base+i];int j=i;while(j>0&&cuts[base+j-1]>value){cuts[base+j]=cuts[base+j-1];j--;}cuts[base+j]=value; }
    }
    usz words=1;for(int v=0;v<n;v++) words += 1+(usz)counts[v];usz bytes=words*8;
    if (output==null || output_capacity<bytes) return -2;
    cut_put_i64(output,0,(long)n);usz at=1;
    for(int v=0;v<n;v++){cut_put_i64(output,at++,counts[v]);for(int i=0;i<counts[v];i++)cut_put_i64(output,at++, (long)cuts[v*MAX_CUTS+i]);}
    return (long)bytes;
}
