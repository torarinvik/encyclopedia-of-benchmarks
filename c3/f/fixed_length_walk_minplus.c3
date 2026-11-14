// Uncompiled exact-length shortest-walk draft.
module fixed_length_walk_minplus;
fn long fixed_length_walk_minplus(long* input, usz length) @export("fixed_length_walk_minplus") {
    const long INF = 1000000000000000;
    if (input == null || length < 4 || length > 261) return -100000002;
    long nv=input[0], k=input[1], source=input[2], target=input[3];
    if (nv<1 || nv>16 || k<0 || k>1000000 || source<0 || source>=nv || target<0 || target>=nv || length != 4+(usz)(nv*nv)) return -100000002;
    usz n=(usz)nv; long[256] matrix; long[256] next; long[16] distance; long[16] temp;
    for (usz i=0; i<n; i++) {
        distance[i]=INF;
        for (usz j=0; j<n; j++) {
            long w=input[4+i*n+j];
            if (w!=1000000 && (w < -100 || w>100)) return -100000002;
            matrix[16*i+j]=w==1000000 ? INF : w;
        }
    }
    distance[(usz)source]=0;
    while (k>0) {
        if ((k & 1)!=0) {
            for (usz j=0; j<n; j++) {
                temp[j]=INF;
                for (usz i=0; i<n; i++)
                    if (distance[i]!=INF && matrix[16*i+j]!=INF && distance[i]+matrix[16*i+j]<temp[j]) temp[j]=distance[i]+matrix[16*i+j];
            }
            for (usz i=0; i<n; i++) distance[i]=temp[i];
        }
        k/=2;
        if (k>0) {
            for (usz i=0; i<n; i++) for (usz j=0; j<n; j++) {
                next[16*i+j]=INF;
                for (usz p=0; p<n; p++) {
                    long a=matrix[16*i+p], b=matrix[16*p+j];
                    if (a!=INF && b!=INF && a+b<next[16*i+j]) next[16*i+j]=a+b;
                }
            }
            for (usz i=0; i<n; i++) for (usz j=0; j<n; j++) matrix[16*i+j]=next[16*i+j];
        }
    }
    return distance[(usz)target]==INF ? -100000001 : distance[(usz)target];
}
