#include <cstddef>
#include <cstdint>

namespace {
constexpr int N=64, B=128;
uint64_t hv(uint64_t h, int64_t v){uint64_t x=(uint64_t)v;for(int i=0;i<8;i++)h=(h^((x>>(8*i))&255))*UINT64_C(0x100000001b3);return h;}
}
extern "C" int64_t generic_hash_map(const int64_t* a,size_t n){
 if(!a||n<1||n>385||a[0]<0||a[0]>128||n!=1+3*(size_t)a[0])return -1;
 int64_t k[N]{},v[N]{};int next[N],head[B];bool active[N]{};for(int&i:next)i=-1;for(int&i:head)i=-1;int size=0,bc=16;uint64_t h=UINT64_C(0xcbf29ce484222325);
 for(int oi=0;oi<a[0];oi++){int64_t op=a[1+3*oi],key=a[2+3*oi],val=a[3+3*oi];if(key<0||key>1000000)return -1;int b=(int)(key%bc),found=-1;for(int j=head[b];j>=0;j=next[j])if(k[j]==key){found=j;break;}
 if(op==0){if(val< -1000000||val>1000000)return -1;if(found>=0)v[found]=val;else{if(size>=N)return -1;int j=0;while(active[j])j++;active[j]=true;k[j]=key;v[j]=val;next[j]=head[b];head[b]=j;size++;if(size*4>bc*3&&bc<B){bc*=2;for(int&i:head)i=-1;for(int q=0;q<N;q++)if(active[q]){b=(int)(k[q]%bc);next[q]=head[b];head[b]=q;}}}}
 else if(op==1||op==3){if(val!=0)return -1;h=hv(h,op==1?(found>=0?v[found]:INT64_MIN):(found>=0));}
 else if(op==2){if(val!=0)return -1;if(found>=0){int prev=-1;for(int j=head[b];j>=0;j=next[j]){if(j==found){if(prev<0)head[b]=next[j];else next[prev]=next[j];break;}prev=j;}active[found]=false;size--;}}
 else if(op==4){if(key!=0||val!=0)return -1;h=hv(h,size);}else return -1;
 }
 h=hv(h,size);bool used[N]{};for(int rank=0;rank<size;rank++){int best=-1;for(int i=0;i<N;i++)if(active[i]&&!used[i]&&(best<0||k[i]<k[best]))best=i;used[best]=true;h=hv(hv(h,k[best]),v[best]);}return (int64_t)h;
}
