module thorup_zwick_distance_oracle;

const usz N = 12;
const usz M = 66;
const usz Q = 32;
const long INF = 0x3fffffffffffffff;

fn long thorup_zwick_distance_oracle(long* input, usz length, uint8* output, usz capacity) @export("thorup_zwick_distance_oracle") {
    if (input == null || length < 4 || length > 266) return -1;
    long n64=input[0], m64=input[1], mask=input[2];
    if (n64 < 1 || n64 > (long)N || m64 < 0 || m64 > (long)M || mask <= 0) return -1;
    usz n=(usz)n64, m=(usz)m64;
    ulong bits=(ulong)mask;
    if ((bits >> n) != 0) return -1;
    usz q_at=3+3*m;
    if (q_at >= length || input[q_at] < 0 || input[q_at] > (long)Q) return -1;
    usz q=(usz)input[q_at];
    if (length != q_at+1+2*q) return -1;
    long[N][N] d = zeroed;
    for (usz i=0;i<n;i++) for (usz j=0;j<n;j++) d[i][j]=if i==j {0} else {INF};
    for (usz e=0;e<m;e++) {
        long ur=input[3+3*e], vr=input[4+3*e], w=input[5+3*e];
        if (ur<0 || vr<=ur || vr>=n64 || w<1 || w>1000) return -1;
        usz u=(usz)ur,v=(usz)vr;
        if (d[u][v] != INF) return -1;
        d[u][v]=w;d[v][u]=w;
    }
    for (usz k=0;k<n;k++) for (usz i=0;i<n;i++) for (usz j=0;j<n;j++) {
        if (d[i][k] != INF && d[k][j] != INF && d[i][k]+d[k][j] < d[i][j]) d[i][j]=d[i][k]+d[k][j];
    }
    for (usz i=0;i<n;i++) for (usz j=0;j<n;j++) if (d[i][j]==INF) return -1;
    usz[N] nearest=zeroed; long[N] near_d=zeroed;
    for (usz v=0;v<n;v++) {
        nearest[v]=N;near_d[v]=INF;
        for (usz a=0;a<n;a++) if (((bits >> a)&1)!=0) {
            if (d[v][a]<near_d[v] || (d[v][a]==near_d[v] && a<nearest[v])) {nearest[v]=a;near_d[v]=d[v][a];}
        }
    }
    bool[N][N] bunch=zeroed;
    for (usz u=0;u<n;u++) for (usz x=0;x<n;x++) bunch[u][x]=(((bits>>x)&1)!=0)||d[u][x]<near_d[u];
    long[Q+1] staged=zeroed;staged[0]=(long)q;
    for (usz z=0;z<q;z++) {
        long ar=input[q_at+1+2*z],br=input[q_at+2+2*z];
        if(ar<0||ar>=n64||br<0||br>=n64)return -1;
        usz u=(usz)ar,v=(usz)br;bool found=false;
        for(usz level=0;level<2;level++) {
            usz pivot=if level==0 {v} else {nearest[v]};
            if(bunch[u][pivot]){staged[z+1]=d[u][pivot]+d[v][pivot];found=true;break;}
            usz tmp=u;u=v;v=tmp;
        }
        if(!found)return -1;
    }
    usz bytes=8*(q+1);
    if(output==null||capacity<bytes)return -2;
    for(usz i=0;i<q+1;i++){ulong word=(ulong)staged[i];for(usz b=0;b<8;b++){output[i*8+b]=(uint8)(word&255);word>>=8;}}
    return (long)bytes;
}
