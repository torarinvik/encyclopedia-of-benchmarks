#include <cstddef>
#include <cstdint>
#include <array>
#include <queue>
extern "C" std::int64_t lee_breadth_first_search(const std::int64_t*v,std::size_t n){if(!v||n<6||n>70)return -2;auto R=v[0],C=v[1],sr=v[2],sc=v[3],dr=v[4],dc=v[5];if(R<1||R>8||C<1||C>8||n!=6+R*C||sr<0||sr>=R||dr<0||dr>=R||sc<0||sc>=C||dc<0||dc>=C)return -2;std::array<int,64>a{};std::array<int,64>d;d.fill(-1);for(int i=0;i<R*C;i++){if(v[6+i]!=0&&v[6+i]!=1)return -2;a[i]=v[6+i];}int s=sr*C+sc,t=dr*C+dc;if(!a[s]||!a[t])return -1;std::queue<int>q;q.push(s);d[s]=0;const int rr[4]={-1,0,0,1},cc[4]={0,-1,1,0};while(!q.empty()){int u=q.front();q.pop();if(u==t)return d[u];int r=u/C,c=u%C;for(int k=0;k<4;k++){int y=r+rr[k],x=c+cc[k];if(y>=0&&y<R&&x>=0&&x<C){int w=y*C+x;if(a[w]&&d[w]<0){d[w]=d[u]+1;q.push(w);}}}}return -1;}
