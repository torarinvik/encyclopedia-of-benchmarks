module uncommon_words;
fn long uncommon_words(long* v, usz n, char* output, usz cap) @export("uncommon_words") {
 if(v==null||n<1||n>1089||v[0]<0||v[0]>64)return -1;long lens[64]={},counts[64]={},words[64][16]={},temp[1089]={};usz d=0,p=1;
 for(usz w=0;w<(usz)v[0];w++){if(p>=n||v[p]<1||v[p]>16||v[p]>(long)(n-p-1))return -1;usz l=(usz)v[p++];for(usz j=0;j<l;j++)if(v[p+j]<'a'||v[p+j]>'z')return -1;usz id=0;for(;id<d;id++)if((usz)lens[id]==l){usz j=0;while(j<l&&words[id][j]==v[p+j])j++;if(j==l)break;}if(id==d){lens[d]=(long)l;for(usz j=0;j<l;j++)words[d][j]=v[p+j];d++;}counts[id]++;p+=l;}
 if(p!=n)return -1;usz at=0;for(usz id=0;id<d;id++)if(counts[id]==1){for(usz j=0;j<(usz)lens[id];j++)temp[at++]=words[id][j];temp[at++]='\n';}if(at>0)at--;temp[at++]=0;if(output==null||cap<at)return -2;for(usz i=0;i<at;i++)output[i]=(char)temp[i];return (long)at;
}
