module rmq_cartesian_tree_fcb;
const usz N=64, Q=64, E=127, B=127, L=8, M=4;

fn int shallower(int a,int b,int* d){return d[a]<d[b]?a:d[b]<d[a]?b:(a<b?a:b);}
fn int rmq(int a,int z,usz ec,usz bs,int* d,int* pat,int* micro,int* macro,int* logs){
    usz ba=(usz)a/bs,bz=(usz)z/bs,oa=(usz)a%bs,oz=(usz)z%bs;
    if(ba==bz)return (int)(ba*bs+(usz)micro[(pat[ba]*4+oa)*4+oz]);
    usz xa=ba*bs,xz=bz*bs,na=ec-xa<bs?ec-xa:bs;
    int best=(int)(xa+(usz)micro[(pat[ba]*4+oa)*4+na-1]);
    best=shallower(best,(int)(xz+(usz)micro[(pat[bz]*4)*4+oz]),d);
    if(bz>ba+1){usz lo=ba+1,hi=bz-1,c=hi-lo+1,k=(usz)logs[c],span=(usz)1<<k;
        best=shallower(best,macro[k*B+lo],d);best=shallower(best,macro[k*B+hi-span+1],d);}return best;
}

fn long rmq_cartesian_tree_fcb(long* in,usz len,char* out,usz cap) @export("rmq_cartesian_tree_fcb") {
    if(in==null||len<2||len>195||in[0]<1||in[0]>(long)N||in[1]<0||in[1]>(long)Q)return -1;
    usz n=(usz)in[0],q=(usz)in[1],qo=2+n;if(len!=2+n+2*q)return -1;
    long[N] val;for(usz i=0;i<n;i++){val[i]=in[2+i];if(val[i]<-1000||val[i]>1000)return -1;}
    for(usz i=0;i<q;i++){long a=in[qo+2*i],z=in[qo+2*i+1];if(a<0||a>z||z>=(long)n)return -1;}
    if(out==null||cap<q+1)return -2;
    int[N] left,right,parent,mono;for(usz i=0;i<n;i++){left[i]=-1;right[i]=-1;parent[i]=-1;}
    usz sp=0;for(usz i=0;i<n;i++){int last=-1;while(sp>0&&val[(usz)mono[sp-1]]>val[i])last=mono[--sp];
        if(sp>0){int p=mono[sp-1];right[p]=(int)i;parent[i]=p;}if(last>=0){left[i]=last;parent[last]=(int)i;}mono[sp++]=(int)i;}
    int root=0;while(parent[root]>=0)root++;
    int[E] euler,depth,node_depth,first,frame_node;int[N] frame_state;
    usz ec=1,top=1;euler[0]=root;depth[0]=0;first[root]=0;node_depth[root]=0;frame_node[0]=root;frame_state[0]=0;
    while(top>0){usz slot=top-1;int v=frame_node[slot];
        if(frame_state[slot]==0){if(left[v]>=0){int c=left[v];frame_state[slot]=1;node_depth[c]=node_depth[v]+1;first[c]=(int)ec;euler[ec]=c;depth[ec++]=node_depth[c];frame_node[top]=c;frame_state[top++]=0;}
            else if(right[v]>=0){int c=right[v];frame_state[slot]=2;node_depth[c]=node_depth[v]+1;first[c]=(int)ec;euler[ec]=c;depth[ec++]=node_depth[c];frame_node[top]=c;frame_state[top++]=0;}else top--;}
        else if(frame_state[slot]==1){euler[ec]=v;depth[ec++]=node_depth[v];if(right[v]>=0){int c=right[v];frame_state[slot]=2;node_depth[c]=node_depth[v]+1;first[c]=(int)ec;euler[ec]=c;depth[ec++]=node_depth[c];frame_node[top]=c;frame_state[top++]=0;}else top--;}
        else{euler[ec]=v;depth[ec++]=node_depth[v];top--;}}
    usz lg=0;for(usz x=ec;x>1;x/=2)lg++;usz bs=lg/2;if(bs<1)bs=1;usz blocks=(ec+bs-1)/bs;
    int[8*16] micro;int[B] pat;int[B+1] logs;int[L*B] macro;
    for(usz s=0;s<((usz)1<<(bs-1));s++){int[M] rel;rel[0]=0;for(usz j=0;j+1<bs;j++)rel[j+1]=rel[j]+(((s>>j)&1)!=0?1:-1);
        for(usz a=0;a<bs;a++)for(usz z=a;z<bs;z++){usz best=a;for(usz k=a+1;k<=z;k++)if(rel[k]<rel[best])best=k;micro[(s*4+a)*4+z]=(int)best;}}
    for(usz b=0;b<blocks;b++){usz base=b*bs,end=ec<base+bs?ec:base+bs;int best=(int)base;pat[b]=0;
        for(usz k=base;k+1<end;k++){if(depth[k+1]>depth[k])pat[b]|=1<<(k-base);best=shallower(best,(int)(k+1),&depth[0]);}macro[b]=best;}
    logs[0]=0;logs[1]=0;for(usz c=2;c<=blocks;c++)logs[c]=logs[c/2]+1;usz levels=1;
    while(((usz)1<<levels)<=blocks&&levels<L){usz half=(usz)1<<(levels-1),span=2*half;for(usz b=0;b+span<=blocks;b++)macro[levels*B+b]=shallower(macro[(levels-1)*B+b],macro[(levels-1)*B+b+half],&depth[0]);levels++;}
    int[Q] ans;for(usz i=0;i<q;i++){usz a=(usz)first[(usz)in[qo+2*i]],z=(usz)first[(usz)in[qo+2*i+1]];if(a>z){usz t=a;a=z;z=t;}
        int at=rmq((int)a,(int)z,ec,bs,&depth[0],&pat[0],&micro[0],&macro[0],&logs[0]);ans[i]=euler[(usz)at];}
    out[0]=(char)q;for(usz i=0;i<q;i++)out[i+1]=(char)ans[i];return (long)(q+1);
}
