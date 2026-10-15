module adtfraction;

fn int wrap_add(int a, int b) { return @bitcast(int, (uint)a + (uint)b); }
fn int wrap_mul(int a, int b) { return @bitcast(int, (uint)a * (uint)b); }
fn long pack(int n, int d) { return (long)n * 4294967296 + (long)(uint)d; }

fn long adtfraction(long* input, usz length) @export("adtfraction") {
    if (input == null || length != 5) return -1;
    for (usz i = 0; i < 5; i++) if (input[i] < -100000 || input[i] > 100000) return -1;
    if (input[0] < 0 || input[0] > 4) return -1;
    int op=(int)input[0], n=(int)input[1], d=(int)input[2], m=(int)input[3], e=(int)input[4];
    if (op == 0) { if(d==0||e==0)return -1; int den=wrap_mul(d,e); if(den==0)return -1; return pack(wrap_add(wrap_mul(d,m),wrap_mul(n,e)),den); }
    if (op == 1) { if(d==0)return -1; return pack(wrap_mul(n,m),d); }
    if (op == 2) { if(d==0||e==0)return -1; int den=wrap_mul(d,e); if(den==0)return -1; return pack(wrap_mul(n,m),den); }
    if (op == 3) { if(n==0)return -1; return pack(d,n); }
    if (d==0)return -1; float value=(float)n/(float)d; uint bits=@bitcast(uint,value); return (long)bits;
}
