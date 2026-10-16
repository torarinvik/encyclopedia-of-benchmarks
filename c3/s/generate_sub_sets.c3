module generate_sub_sets;

const usz MAX_ITEMS = 12;
const long MAX_SAFE = 9007199254740991;
fn void put32(uchar* out, usz* pos, uint value) { uint bits=value; for(usz i=0;i<4;i++){out[*pos]=(uchar)(bits&255);*pos+=1;bits>>=8;} }
fn void put64(uchar* out, usz* pos, long value) { ulong bits=(ulong)value; for(usz i=0;i<8;i++){out[*pos]=(uchar)(bits&255);*pos+=1;bits>>=8;} }

fn long generate_sub_sets(long* input, usz length, uchar* output, usz capacity) @export("generate_sub_sets") {
    if(input==null || length<1 || length>13 || input[0]<0 || input[0]>12) return -1;
    usz n=(usz)input[0]; if(length!=n+1) return -1;
    for(usz i=0;i<n;i++) if(input[i+1] < -MAX_SAFE || input[i+1] > MAX_SAFE) return -1;
    usz subsets=(usz)1<<n; usz total_items=n==0?0:n*(subsets/2); usz needed=4+4*subsets+8*total_items;
    if(output==null || capacity<needed) return -2;
    usz pos=0; put32(output,&pos,(uint)subsets);
    for(usz mask=0;mask<subsets;mask++) {
        uint count=0; for(usz j=0;j<n;j++) if((mask & ((usz)1<<j))!=0) count++;
        put32(output,&pos,count);
        for(usz j=0;j<n;j++) if((mask & ((usz)1<<j))!=0) put64(output,&pos,input[j+1]);
    }
    return (long)pos;
}
