module fast_walsh_hadamard_transform;
fn long fast_walsh_hadamard_transform(long* v, usz len, char* out, usz cap) @export("fast_walsh_hadamard_transform") {
    if (v == null || len < 2 || len > 130 || (v[0] != 0 && v[0] != 1) || v[1] < 1 || v[1] > 128) return -1;
    usz n = (usz)v[1]; if ((n & (n - 1)) != 0 || len != n + 2) return -1;
    long[128] a = {0}; for (usz i = 0; i < n; i++) { if (v[i+2] < -10000 || v[i+2] > 10000) return -1; a[i] = v[i+2]; }
    for (usz h = 1; h < n; h *= 2) for (usz b = 0; b < n; b += 2*h) for (usz j = 0; j < h; j++) { long x=a[b+j], y=a[b+j+h]; a[b+j]=x+y; a[b+j+h]=x-y; }
    if (v[0] == 1) for (usz i=0;i<n;i++){if(a[i]%(long)n!=0)return -1;a[i]/=(long)n;}
    if(n*8>cap||out==null)return -2;
    for(usz i=0;i<n;i++){ulong x=(ulong)a[i];for(usz k=0;k<8;k++)out[i*8+k]=(char)((x>>(k*8))&255);}
    return (long)n;
}
