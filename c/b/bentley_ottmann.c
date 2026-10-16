#include <stddef.h>
#include <stdint.h>
#define MAX_SEGMENTS 24
#define MAX_EVENTS (2*MAX_SEGMENTS+MAX_SEGMENTS*(MAX_SEGMENTS-1)/2)
typedef struct{int64_t x1,y1,x2,y2;} Segment;
typedef struct{int64_t x,y;int a,b,type,done;} Event;
static int64_t cross(int64_t ax,int64_t ay,int64_t bx,int64_t by){return ax*by-ay*bx;}
static int intersect(const Segment*a,const Segment*b,int64_t*x,int64_t*y){int64_t rx=a->x2-a->x1,ry=a->y2-a->y1,sx=b->x2-b->x1,sy=b->y2-b->y1,den=cross(rx,ry,sx,sy);if(!den)return 0;int64_t qx=b->x1-a->x1,qy=b->y1-a->y1,t=cross(qx,qy,sx,sy),u=cross(qx,qy,rx,ry);if(den<0){den=-den;t=-t;u=-u;}if(t<=0||t>=den||u<=0||u>=den)return 0;int64_t xn=a->x1*den+t*rx,yn=a->y1*den+t*ry;if(xn%den||yn%den)return 0;*x=xn/den;*y=yn/den;return 1;}
static int status_less(const Segment*s,int a,int b,int64_t x){int64_t da=s[a].x2-s[a].x1,db=s[b].x2-s[b].x1,na=s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1),nb=s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1),cmp=na*db-nb*da;if(cmp)return cmp<0;int64_t slope=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da;return slope?slope<0:a<b;}
static void put_i64(uint8_t*out,size_t slot,int64_t v){uint64_t b=(uint64_t)v;for(size_t i=0;i<8;++i)out[slot*8+i]=(uint8_t)(b>>(8*i));}
int64_t bentley_ottmann(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<1||input[0]<0||input[0]>MAX_SEGMENTS)return -1;size_t n=(size_t)input[0];if(length!=1+4*n)return -1;Segment seg[MAX_SEGMENTS];for(size_t i=0;i<n;++i){int64_t x1=input[1+4*i],y1=input[2+4*i],x2=input[3+4*i],y2=input[4+4*i];if(x1< -1000||x1>1000||x2< -1000||x2>1000||y1< -1000||y1>1000||y2< -1000||y2>1000||x1==x2)return -1;if(x1<x2){seg[i]=(Segment){x1,y1,x2,y2};}else{seg[i]=(Segment){x2,y2,x1,y1};}}
 Event ev[MAX_EVENTS];size_t ec=0;for(size_t i=0;i<n;++i){ev[ec++]=(Event){seg[i].x1,seg[i].y1,(int)i,-1,0,0};ev[ec++]=(Event){seg[i].x2,seg[i].y2,(int)i,-1,1,0};}uint8_t scheduled[MAX_SEGMENTS][MAX_SEGMENTS]={{0}};int active[MAX_SEGMENTS];size_t ac=0;int64_t pts[MAX_SEGMENTS*(MAX_SEGMENTS-1)/2][2];size_t pc=0;
 for(;;){size_t ei=ec;for(size_t j=0;j<ec;++j)if(!ev[j].done&&(ei==ec||ev[j].x<ev[ei].x||(ev[j].x==ev[ei].x&&ev[j].y<ev[ei].y)))ei=j;if(ei==ec)break;Event e=ev[ei];ev[ei].done=1;
  if(e.type==0){active[ac++]=e.a;}else if(e.type==1){for(size_t j=0;j<ac;++j)if(active[j]==e.a){for(size_t k=j+1;k<ac;++k)active[k-1]=active[k];--ac;break;}}else{pts[pc][0]=e.x;pts[pc++][1]=e.y;}
  for(size_t i=1;i<ac;++i){int v=active[i];size_t j=i;while(j>0&&status_less(seg,v,active[j-1],e.x)){active[j]=active[j-1];--j;}active[j]=v;}
  for(size_t i=1;i<ac;++i){int a=active[i-1],b=active[i];if(scheduled[a][b])continue;int64_t x,y;if(intersect(&seg[a],&seg[b],&x,&y)&&x>e.x){if(ec>=MAX_EVENTS)return -1;ev[ec++]=(Event){x,y,a,b,2,0};scheduled[a][b]=scheduled[b][a]=1;}}
 }
 for(size_t i=1;i<pc;++i){int64_t x=pts[i][0],y=pts[i][1];size_t j=i;while(j>0&&(pts[j-1][0]>x||(pts[j-1][0]==x&&pts[j-1][1]>y))){pts[j][0]=pts[j-1][0];pts[j][1]=pts[j-1][1];--j;}pts[j][0]=x;pts[j][1]=y;}
 size_t bytes=(1+2*pc)*8;if(!output||capacity<bytes)return -2;put_i64(output,0,(int64_t)pc);for(size_t i=0;i<pc;++i){put_i64(output,1+2*i,pts[i][0]);put_i64(output,2+2*i,pts[i][1]);}return (int64_t)bytes;
}
