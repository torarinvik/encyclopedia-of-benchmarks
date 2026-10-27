module suffix_tree_pattern_occurrences;
const usz MAX_N=24;const usz MAX_M=12;const usz MAX_INPUT=39;const usz MAX_NODES=51;const usz MAX_EDGES=50;
fn long code_at(long*in,usz n,usz p){return p==n?-1:in[1+p];}
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
fn bool suffix_less(long*in,usz n,usz a,usz b){usz p=0;while(a+p<=n&&b+p<=n){long x=code_at(in,n,a+p),y=code_at(in,n,b+p);if(x!=y)return x<y;p+=1;}return a<b;}
fn void add_edge(usz parent,usz child,usz*first,usz*last,usz*children,usz*next,usz*ec){*ec+=1;usz e=*ec;children[e]=child;next[e]=0;if(first[parent]==0)first[parent]=e;else next[last[parent]]=e;last[parent]=e;}
long suffix_tree_pattern_occurrences(long*in,usz len,char*out,usz cap) @export("suffix_tree_pattern_occurrences"){
 if(in==null||len<3||len>MAX_INPUT)return -1;long nr=in[0];if(nr<0||nr>24)return -1;usz n=(usz)nr;if(len<2+n)return -1;long mr=in[1+n];if(mr<1||mr>12||len!=2+n+(usz)mr)return -1;usz m=(usz)mr;
 for(usz i=0;i<n;i+=1)if(in[1+i]<0||in[1+i]>127)return -1;for(usz i=0;i<m;i+=1)if(in[2+n+i]<0||in[2+n+i]>127)return -1;
 usz[MAX_NODES] start=zeroed,length=zeroed,suffix=zeroed,first=zeroed,last=zeroed;usz[MAX_NODES] child_count=zeroed;usz[MAX_EDGES+1] target=zeroed,next=zeroed;usz node_count=1,edge_count=0;
 for(usz s=0;s<=n;s+=1){usz sl=n+1-s,off=0,node=0;while(off<sl){long c=code_at(in,n,s+off);usz e=first[node];while(e!=0&&code_at(in,n,start[target[e]])!=c)e=next[e];if(e==0){if(node_count>=MAX_NODES)return -1;usz leaf=node_count;node_count+=1;start[leaf]=s+off;length[leaf]=sl-off;suffix[leaf]=s;add_edge(node,leaf,&first[0],&last[0],&target[0],&next[0],&edge_count);break;}usz child=target[e],common=0;while(common<length[child]&&off+common<sl&&code_at(in,n,s+off+common)==code_at(in,n,start[child]+common))common+=1;if(common==length[child]){off+=common;node=child;continue;}if(node_count>=MAX_NODES)return -1;usz split=node_count;node_count+=1;start[split]=start[child];length[split]=common;start[child]+=common;length[child]-=common;target[e]=split;add_edge(split,child,&first[0],&last[0],&target[0],&next[0],&edge_count);off+=common;node=split;}}
 usz node=0,off=0;bool matched=false;while(off<m){long want=in[2+n+off];usz e=first[node];while(e!=0&&code_at(in,n,start[target[e]])!=want)e=next[e];if(e==0)break;usz child=target[e],common=0;while(common<length[child]&&off+common<m&&code_at(in,n,start[child]+common)==in[2+n+off+common])common+=1;if(off+common==m){node=child;matched=true;break;}if(common!=length[child])break;off+=common;node=child;}
 usz starts[MAX_N],count=0;if(matched){usz stack[MAX_NODES],top=1;stack[0]=node;while(top>0){top-=1;usz x=stack[top];if(first[x]==0&&length[x]>0)starts[count++]=suffix[x];usz e=first[x];while(e!=0){stack[top++]=target[e];e=next[e];}}}
 for(usz i=1;i<count;i+=1){usz x=starts[i],j=i;while(j>0&&suffix_less(in,n,x,starts[j-1])){starts[j]=starts[j-1];j-=1;}starts[j]=x;}
 usz bytes=8*(1+count);if(out==null||cap<bytes)return -2;put64(out,0,(long)count);for(usz i=0;i<count;i+=1)put64(out,8+8*i,(long)starts[i]);return (long)bytes;
}
