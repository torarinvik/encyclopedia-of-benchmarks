// Uncompiled exact-length walk counting draft.
module fixed_length_walk_count;
fn long fixed_length_walk_count(long* input, usz length) @export("fixed_length_walk_count") {
    const long MOD = 1000000007;
    if (input==null || length<4 || length>261) return -1;
    long nv=input[0], k=input[1], source=input[2], target=input[3];
    if (nv<1 || nv>16 || k<0 || k>1000000000 || source<0 || source>=nv || target<0 || target>=nv || length!=4+(usz)(nv*nv)) return -1;
    usz n=(usz)nv; long[256] matrix=zeroed, next; long[16] vector=zeroed, temp;
    for (usz i=0; i<n; i++) for (usz j=0; j<n; j++) {
        long value=input[4+i*n+j];
        if (value<0 || value>100) return -1;
        matrix[16*i+j]=value;
    }
    vector[(usz)source]=1;
    while (k>0) {
        if ((k&1)!=0) {
            for (usz j=0; j<n; j++) {
                temp[j]=0;
                for (usz i=0; i<n; i++) temp[j]=(temp[j]+vector[i]*matrix[16*i+j])%MOD;
            }
            for (usz i=0; i<n; i++) vector[i]=temp[i];
        }
        k/=2;
        if (k>0) {
            for (usz i=0; i<n; i++) for (usz j=0; j<n; j++) {
                next[16*i+j]=0;
                for (usz p=0; p<n; p++) next[16*i+j]=(next[16*i+j]+matrix[16*i+p]*matrix[16*p+j])%MOD;
            }
            for (usz i=0; i<n; i++) for (usz j=0; j<n; j++) matrix[16*i+j]=next[16*i+j];
        }
    }
    return vector[(usz)target];
}
