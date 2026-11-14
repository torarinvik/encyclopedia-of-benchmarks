module discrete_logarithm_fixed_mod;

fn long discrete_logarithm_fixed_mod(long* input, usz length, uchar* output, usz capacity) @export("discrete_logarithm_fixed_mod") {
    if (input==null || length<3 || length>259) return -1;
    if (input[0]<2 || input[0]>4093 || input[1]<1 || input[1]>=input[0] || input[2]<1 || input[2]>256) return -1;
    int p=(int)input[0], g=(int)input[1], n=(int)input[2];
    if (length!=(usz)(n+3)) return -1;
    for (int d=2;d*d<=p;d++) if (p%d==0) return -1;
    for (int i=0;i<n;i++) if (input[3+i]<1 || input[3+i]>=p) return -1;
    short[4094] table;
    for (int i=0;i<p;i++) table[i]=-1;
    int residue=1;
    for (int exponent=0;exponent<p-1;exponent++) {
        if (table[residue]!=-1) return -1;
        table[residue]=(short)exponent;
        residue=residue*g%p;
    }
    if (residue!=1) return -1;
    if (output==null || capacity<(usz)(8*n)) return -2;
    for (int i=0;i<n;i++) {
        ulong value=(ulong)table[(int)input[3+i]];
        for (int byte=0;byte<8;byte++) output[8*i+byte]=(uchar)(value >> (8*byte));
    }
    return 8*n;
}
