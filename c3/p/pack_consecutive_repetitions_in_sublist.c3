module pack_consecutive_repetitions_in_sublist;
fn uint8 mix(uint h,uint8 b){return (h^(uint)b)*16777619;}
fn uint feed(uint h,uint x){for(uint b=0;b<4;b++)h=mix(h,(uint8)(x>>(8*b)));return h;}
fn long pack_consecutive_repetitions_in_sublist(long* v,usz n) @export("pack_consecutive_repetitions_in_sublist"){
    if(v==null||n<1||n>65||v[0]<0||v[0]>64||n!=(usz)v[0]+1)return -1;
    usz count=(usz)v[0];for(usz i=0;i<count;i++)if(v[i+1]< -2147483648||v[i+1]>2147483647)return -1;
    uint h=2166136261;usz i=0;while(i<count){int32 value=(int32)v[i+1];usz j=i+1;while(j<count&&v[j+1]==(long)value)j++;h=feed(h,(uint)value);h=feed(h,(uint)(j-i));i=j;}return (long)h;
}
