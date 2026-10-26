// Clean-room exact bounded minimum weighted connected dominating set.
module weighted_connected_dominating_set;
const usz N=16;
fn void put(char*out,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(b&255ul);b>>=8;}}
fn long weighted_connected_dominating_set(long*v,usz n,char*out,usz cap) @export("weighted_connected_dominating_set"){
 if(v==null||n<3||n>33||v[0]<1||v[0]>16)return -1;usz count=(usz)v[0];if(n!=1+2*count)return -1;ulong all=((ulong)1<<count)-1;ulong[N] adj={};for(usz i=0;i<count;++i){long mask=v[1+i],weight=v[1+count+i];if(mask<0||(ulong)mask>all||(((ulong)mask&((ulong)1<<i))!=0)||weight<1||weight>1000)return -1;adj[i]=(ulong)mask;}for(usz i=0;i<count;++i)for(usz j=0;j<count;++j)if(((adj[i]>>j)&1ul)!=((adj[j]>>i)&1ul))return -1;
 long best=-1;ulong best_mask=0,mask=1;for(;mask<=all;++mask){ulong dominated=mask;long cost=0;for(usz i=0;i<count;++i)if(((mask>>i)&1ul)!=0){dominated|=adj[i];cost+=v[1+count+i];}if(dominated!=all)continue;ulong seen=mask&(~mask+1),old;do{old=seen;for(usz i=0;i<count;++i)if(((seen>>i)&1ul)!=0)seen|=adj[i]&mask;}while(seen!=old);if(seen==mask&&(best<0||cost<best||(cost==best&&mask<best_mask))){best=cost;best_mask=mask;}}
 if(out==null||cap<16)return -2;put(out,0,best);put(out,8,(long)best_mask);return 16;
}
