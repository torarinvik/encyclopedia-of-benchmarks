/* Clean-room exact Delaunay graph construction by empty circumcircles. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_N=8, MAX_FIELDS=37 };
static int64_t orient(int64_t ax,int64_t ay,int64_t bx,int64_t by,int64_t cx,int64_t cy){return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax);}
static int64_t incircle(int64_t ax,int64_t ay,int64_t bx,int64_t by,int64_t cx,int64_t cy,int64_t dx,int64_t dy){ax-=dx;ay-=dy;bx-=dx;by-=dy;cx-=dx;cy-=dy;int64_t aa=ax*ax+ay*ay,bb=bx*bx+by*by,cc=cx*cx+cy*cy;return aa*(bx*cy-by*cx)-bb*(ax*cy-ay*cx)+cc*(ax*by-ay*bx);}
static void put(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)b;b>>=8;}}
int64_t voronoi_delaunay_empty_circle(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<7||n>17||v[0]<3||v[0]>MAX_N||n!=1+2*(size_t)v[0])return -1;size_t count=(size_t)v[0];int64_t x[MAX_N],y[MAX_N];for(size_t i=0;i<count;++i){x[i]=v[1+2*i];y[i]=v[2+2*i];if(x[i]<-50||x[i]>50||y[i]<-50||y[i]>50)return -1;for(size_t j=0;j<i;++j)if(x[i]==x[j]&&y[i]==y[j])return -1;}
 for(size_t a=0;a<count;++a)for(size_t b=a+1;b<count;++b)for(size_t c=b+1;c<count;++c)if(orient(x[a],y[a],x[b],y[b],x[c],y[c])==0)return -1;
 for(size_t a=0;a<count;++a)for(size_t b=a+1;b<count;++b)for(size_t c=b+1;c<count;++c)for(size_t d=c+1;d<count;++d)if(incircle(x[a],y[a],x[b],y[b],x[c],y[c],x[d],y[d])==0)return -1;
 uint8_t edge[MAX_N][MAX_N]={{0}};for(size_t a=0;a<count;++a)for(size_t b=a+1;b<count;++b)for(size_t c=b+1;c<count;++c){int64_t o=orient(x[a],y[a],x[b],y[b],x[c],y[c]);int empty=1;for(size_t d=0;d<count;++d)if(d!=a&&d!=b&&d!=c){int64_t z=incircle(x[a],y[a],x[b],y[b],x[c],y[c],x[d],y[d]);if((o>0&&z>0)||(o<0&&z<0)){empty=0;break;}}if(empty){edge[a][b]=edge[b][a]=edge[a][c]=edge[c][a]=edge[b][c]=edge[c][b]=1;}}
 int64_t fields[MAX_FIELDS]={0};size_t m=0,at=1;for(size_t a=0;a<count;++a)for(size_t b=a+1;b<count;++b)if(edge[a][b]){fields[at++]=(int64_t)a;fields[at++]=(int64_t)b;++m;}fields[0]=(int64_t)m;size_t bytes=8*at;if(!out||cap<bytes)return -2;for(size_t i=0;i<at;++i)put(out,8*i,fields[i]);return (int64_t)bytes;
}
