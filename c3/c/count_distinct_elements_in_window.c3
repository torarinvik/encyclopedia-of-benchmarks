module count_distinct_elements_in_window;
const usz MAX_N=256;
fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits=(ulong)value; for(usz b=0;b<8;b++){output[offset+b]=(char)(bits&255);bits>>=8;}
}
fn long count_distinct_elements_in_window(long* input, usz length, char* output, usz capacity) @export("count_distinct_elements_in_window") {
    if(input==null||length<3||input[0]<1||input[0]>256)return -1;
    usz n=(usz)input[0]; if(input[1]<1||input[1]>(long)n||length!=n+2)return -1;
    usz k=(usz)input[1], out_n=n-k+1;
    for(usz i=0;i<n;i++)if(input[i+2]<-2147483648L||input[i+2]>2147483647L)return -1;
    if(capacity<out_n*8||output==null)return -2;
    int[256] keys; int[256] counts=zeroed; usz used=0; long distinct=0;
    for(usz i=0;i<k;i++){int v=(int)input[i+2];usz j=0;while(j<used&&keys[j]!=v)j++;if(j==used){keys[used]=v;used++;}if(counts[j]==0)distinct++;counts[j]++;}
    put_i64_le(distinct,output,0);
    for(usz i=k;i<n;i++){
        int incoming=(int)input[i+2];usz j=0;while(j<used&&keys[j]!=incoming)j++;if(j==used){keys[used]=incoming;used++;}if(counts[j]==0)distinct++;counts[j]++;
        int outgoing=(int)input[i-k+2];j=0;while(keys[j]!=outgoing)j++;counts[j]--;if(counts[j]==0)distinct--;
        put_i64_le(distinct,output,(i-k+1)*8);
    }
    return (long)(out_n*8);
}
