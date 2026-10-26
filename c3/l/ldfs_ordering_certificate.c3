// Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
module ldfs_ordering_certificate;
const usz N=8;const usz FIELDS=234;
fn void put(char*o,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;++i){o[at+i]=(char)(b&255ul);b>>=8;}}
fn long ldfs_ordering_certificate(long*v,usz n,char*out,usz cap) @export("ldfs_ordering_certificate"){
 if(v==null||n<3||n>10||v[0]<1||v[0]>8)return -1;usz count=(usz)v[0];if(n!=count+2||v[1]<0||v[1]>=(long)count)return -1;ulong all=((ulong)1<<count)-1;ulong[N] adj={};
 for(usz i=0;i<count;++i){if(v[2+i]<0||(ulong)v[2+i]>all||(((ulong)v[2+i]&((ulong)1<<i))!=0))return -1;adj[i]=(ulong)v[2+i];}for(usz i=0;i<count;++i){for(usz j=0;j<count;++j){if(((adj[i]>>j)&1ul)!=((adj[j]>>i)&1ul))return -1;}}
 ulong reach=(ulong)1<<(usz)v[1];for(usz pass=0;pass<count;++pass){ulong old=reach;for(usz i=0;i<count;++i){if(((reach>>i)&1ul)!=0)reach|=adj[i];}if(old==reach)break;}if(reach!=all)return -1;
 long[N] order={};order[0]=v[1];usz used=1;ulong visited=(ulong)1<<(usz)v[1];while(used<count){usz chosen=count;for(usz x=0;x<count;++x){if(((visited>>x)&1ul)==0){bool wins=chosen==count;if(!wins){usz k=used;while(k>0){--k;usz u=(usz)order[k];ulong xb=(adj[x]>>u)&1ul,yb=(adj[chosen]>>u)&1ul;if(xb!=yb){wins=xb>yb;break;}if(k==0)wins=x<chosen;}}if(wins)chosen=x;}}order[used]=(long)chosen;++used;visited|=(ulong)1<<chosen;}
 long[FIELDS] fields={};fields[0]=(long)count;for(usz i=0;i<count;++i)fields[1+i]=order[i];usz certs=0,at=count+2;
 for(usz i=0;i<count;++i){for(usz j=i+1;j<count;++j){for(usz k=j+1;k<count;++k){usz a=(usz)order[i],b=(usz)order[j],c=(usz)order[k];if(((adj[a]>>c)&1ul)!=0&&((adj[a]>>b)&1ul)==0){long witness=-1;for(usz t=i+1;t<j;++t){usz d=(usz)order[t];if(((adj[d]>>b)&1ul)!=0&&((adj[d]>>c)&1ul)==0){witness=(long)d;break;}}fields[at++]=(long)a;fields[at++]=(long)b;fields[at++]=(long)c;fields[at++]=witness;++certs;}}}}
 fields[count+1]=(long)certs;usz bytes=8*at;if(out==null||cap<bytes)return -2;for(usz i=0;i<at;++i)put(out,8*i,fields[i]);return (long)bytes;
}
