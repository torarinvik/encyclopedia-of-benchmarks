module pairwise_iteration;
fn long pairwise_iteration(long* v,usz n,char* out,usz cap) @export("pairwise_iteration"){
    if(v==null||n<1||n>129||v[0]<0||v[0]>128||n!=(usz)v[0]+1)return -1;
    usz count=(usz)v[0],bytes=count>0?(count-1)*16:0;
    for(usz i=0;i<count;i++)if(v[i+1]<-1000000||v[i+1]>1000000)return -1;
    if(bytes>cap||(bytes>0&&out==null))return -2;
    usz k=0;for(usz i=0;i+1<count;i++)for(usz j=i;j<=i+1;j++){ulong x=(ulong)v[j+1];for(usz b=0;b<8;b++){out[k]=(char)(x>>(8*b));k++;}}
    return (long)bytes;
}
