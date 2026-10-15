module all_construct;
const usz MAX_TARGET=6; const usz MAX_WORDS=4; const usz MAX_WAYS=4096;

fn long all_construct(long* input,usz length,char* output,usz output_capacity) @export("all_construct") {
    if(input==null||length<2||input[0]<0||input[0]>6)return -1;usz n=(usz)input[0];
    for(usz i=0;i<n;i++)if(input[i+1]<97||input[i+1]>122)return -1;usz wc_slot=1+n;
    if(wc_slot>=length||input[wc_slot]<0||input[wc_slot]>4)return -1;usz words=(usz)input[wc_slot],cursor=wc_slot+1;
    usz[MAX_WORDS] starts;usz[MAX_WORDS] word_lengths;
    for(usz w=0;w<words;w++){if(cursor>=length||input[cursor]<1||input[cursor]>6)return -1;usz wl=(usz)input[cursor++];if(cursor+wl>length)return -1;starts[w]=cursor;word_lengths[w]=wl;for(usz j=0;j<wl;j++)if(input[cursor+j]<97||input[cursor+j]>122)return -1;cursor+=wl;}
    if(cursor!=length)return -1;
    char[(MAX_TARGET+1)*MAX_WAYS*MAX_TARGET] paths;char[(MAX_TARGET+1)*MAX_WAYS] path_lengths;usz[MAX_TARGET+1] counts;
    for(usz i=0;i<(MAX_TARGET+1)*MAX_WAYS*MAX_TARGET;i++)paths[i]=0;for(usz i=0;i<(MAX_TARGET+1)*MAX_WAYS;i++)path_lengths[i]=0;for(usz i=0;i<=MAX_TARGET;i++)counts[i]=0;counts[0]=1;
    for(usz pos=0;pos<n;pos++)for(usz w=0;w<words;w++){usz wl=word_lengths[w];if(wl>n-pos)continue;bool matched=true;for(usz j=0;j<wl;j++)if(input[pos+1+j]!=input[starts[w]+j])matched=false;if(!matched)continue;usz ending=pos+wl;for(usz row=0;row<counts[pos];row++){usz dest=counts[ending];if(dest>=MAX_WAYS)return -1;counts[ending]++;usz src=(pos*MAX_WAYS+row)*MAX_TARGET,dst=(ending*MAX_WAYS+dest)*MAX_TARGET,plen=(usz)path_lengths[pos*MAX_WAYS+row];for(usz k=0;k<plen;k++)paths[dst+k]=paths[src+k];paths[dst+plen]=(char)w;path_lengths[ending*MAX_WAYS+dest]=(char)(plen+1);}}
    usz required=0;for(usz row=0;row<counts[n];row++){usz plen=(usz)path_lengths[n*MAX_WAYS+row];required++;for(usz k=0;k<plen;k++){usz w=(usz)paths[(n*MAX_WAYS+row)*MAX_TARGET+k];required+=1+word_lengths[w];}}
    if(required>output_capacity||(required>0&&output==null))return -2;if(counts[n]==0)return 0;usz written=0;
    for(usz row=0;row<counts[n];row++){usz base=(n*MAX_WAYS+row)*MAX_TARGET,plen=(usz)path_lengths[n*MAX_WAYS+row];output[written++]=(char)plen;for(usz k=0;k<plen;k++){usz w=(usz)paths[base+k],wl=word_lengths[w];output[written++]=(char)wl;for(usz j=0;j<wl;j++)output[written++]=(char)input[starts[w]+j];}}
    return (long)counts[n];
}
