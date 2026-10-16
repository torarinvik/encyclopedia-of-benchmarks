module flatten_nested_list;
fn long flatten_nested_list(long* v, usz n) @export("flatten_nested_list") {
    long open = -9223372036854775808, close = open + 1;
    if (v == null || n == 0 || n > 255 || v[0] != open) return -1;
    int depth = 0; bool closed = false; ulong h = 0xcbf29ce484222325;
    for (usz i=0;i<n;i++) {
        long x=v[i];
        if (x==open) { if(closed||(depth==0&&i!=0))return -1;depth++;if(depth>16)return -1; }
        else if (x==close) { if(depth==0)return -1;depth--;if(depth==0){closed=true;if(i+1!=n)return -1;} }
        else { if(depth==0||x< -1000000||x>1000000)return -1;ulong u=(ulong)x;for(int b=0;b<8;b++){h=(h^((u>>(8*b))&255))*0x100000001b3;} }
    }
    if(depth!=0||!closed)return -1;
    ulong sign = 0x8000000000000000;
    if (h < sign) return (long)h;
    ulong magnitude = 0xffffffffffffffff - h + 1;
    if (magnitude == sign) return -9223372036854775807 - 1;
    return -(long)magnitude;
}
