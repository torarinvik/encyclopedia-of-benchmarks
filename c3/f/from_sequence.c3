module from_sequence;
fn usz append_i64(uint8 *b, usz p, long x) {
    uint8 reversed[20]; usz length=0; ulong magnitude=x<0?(ulong)(-(x+1))+1:(ulong)x;
    do { reversed[length]=(uint8)('0'+magnitude%10);length++;magnitude/=10; } while(magnitude!=0);
    b[p++]='<';if(x<0)b[p++]='-';while(length>0){length--;b[p++]=reversed[length];}b[p++]='>';
    b[p++]=' ';b[p++]='-';b[p++]='-';b[p++]='-';b[p++]='>';b[p++]=' ';return p;
}
fn long from_sequence(long *v, usz n, uint8 *out, usz cap) @export("from_sequence") {
    if(v==null||n<2||n>129)return -1;long count=v[0];if(count<1||count>128||n!=(usz)(count+1))return -1;
    uint8 b[3589]={0};usz p=0;for(long i=0;i<count;i++)p=append_i64(b,p,v[i+1]);
    b[p++]='<';b[p++]='E';b[p++]='N';b[p++]='D';b[p++]='>';
    if(out==null||cap<p)return -2;for(usz i=0;i<p;i++)out[i]=b[i];return (long)p;
}
