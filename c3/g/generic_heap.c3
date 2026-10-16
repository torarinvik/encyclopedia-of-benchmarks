module generic_heap;
fn ulong hashv(ulong h,long v){ulong b=(ulong)v;for(int i=0;i<8;i++)h=(h^((b>>(8*i))&255))*0x100000001b3;return h;}
fn void sw(int i,int j,long* ids,long* ps,int* pos){long t=ids[i];ids[i]=ids[j];ids[j]=t;t=ps[i];ps[i]=ps[j];ps[j]=t;pos[ids[i]]=i;pos[ids[j]]=j;}
fn void up(int i,long* ids,long* ps,int* pos){while(i>0){int q=(i-1)/2;if(ps[i]<=ps[q])break;sw(i,q,ids,ps,pos);i=q;}}
fn void down(int i,int z,long* ids,long* ps,int* pos){while(2*i+1<z){int q=2*i+1;if(q+1<z&&ps[q+1]>ps[q])q++;if(ps[i]>=ps[q])break;sw(i,q,ids,ps,pos);i=q;}}
fn long generic_heap(long* a,usz n) @export("generic_heap"){
 if(a==null||n<1||n>769||a[0]<0||a[0]>256||n!=1+3*(usz)a[0])return -1;
 long[128] ids;long[128] ps;int[4096] pos;for(int i=0;i<4096;i++)pos[i]=-1;int z=0;ulong h=0xcbf29ce484222325;
 for(int k=0;k<(int)a[0];k++){long op=a[1+3*k];long id=a[2+3*k];long v=a[3+3*k];if(op==0){if(id<0||id>=4096||v<-2147483648||v>2147483647||pos[id]>=0||z>=128)return -1;ids[z]=id;ps[z]=v;pos[id]=z;up(z,&ids[0],&ps[0],&pos[0]);z++;}else if(op==1||op==2){if(id!=0||v!=0||z==0)return -1;long ri=ids[0];long rv=ps[0];if(op==2){sw(0,z-1,&ids[0],&ps[0],&pos[0]);z--;pos[ri]=-1;if(z>0)down(0,z,&ids[0],&ps[0],&pos[0]);}h=hashv(hashv(h,ri),rv);}else if(op==3){if(id<0||id>=4096||v<-2147483648||v>2147483647||pos[id]<0)return -1;int i=pos[id];ps[i]=v;up(i,&ids[0],&ps[0],&pos[0]);}else if(op==4||op==5){if(id!=0||v!=0)return -1;h=hashv(h,op==4?z:(z==0?1:0));}else { return -1; }}
 return (long)h;
}
