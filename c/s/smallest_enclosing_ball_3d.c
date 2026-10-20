/* Welzl-style 3D minimum enclosing ball, based on the MIT-licensed source cited in the package README. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

typedef struct { double x,y,z; } SebPoint;
typedef struct { SebPoint c; double r; } SebSphere;
static SebPoint sub3(SebPoint a,SebPoint b){return (SebPoint){a.x-b.x,a.y-b.y,a.z-b.z};}
static SebPoint add3(SebPoint a,SebPoint b){return (SebPoint){a.x+b.x,a.y+b.y,a.z+b.z};}
static SebPoint mul3(SebPoint a,double s){return (SebPoint){a.x*s,a.y*s,a.z*s};}
static double dot3(SebPoint a,SebPoint b){return a.x*b.x+a.y*b.y+a.z*b.z;}
static SebPoint cross3(SebPoint a,SebPoint b){return (SebPoint){a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
static double det3(SebPoint a,SebPoint b,SebPoint c){return dot3(a,cross3(b,c));}
static SebSphere invalid3(void){return (SebSphere){{0,0,0},-1};}
static SebSphere through3(const SebPoint *p,int n){
    if(n==1)return (SebSphere){p[0],0};
    if(n==2){SebPoint c=mul3(add3(p[0],p[1]),0.5);return (SebSphere){c,sqrt(dot3(sub3(p[0],c),sub3(p[0],c))) };}
    if(n==3){SebPoint u=sub3(p[1],p[0]),v=sub3(p[2],p[0]),w=cross3(u,v);double den=2*dot3(w,w);if(den<1e-24)return invalid3();SebPoint off=mul3(add3(mul3(cross3(v,w),dot3(u,u)),mul3(cross3(w,u),dot3(v,v))),1.0/den);SebPoint c=add3(p[0],off);return (SebSphere){c,sqrt(dot3(sub3(c,p[0]),sub3(c,p[0]))) };}
    SebPoint a=mul3(sub3(p[1],p[0]),2),b=mul3(sub3(p[2],p[0]),2),c=mul3(sub3(p[3],p[0]),2);double qa=dot3(p[1],p[1])-dot3(p[0],p[0]),qb=dot3(p[2],p[2])-dot3(p[0],p[0]),qc=dot3(p[3],p[3])-dot3(p[0],p[0]);double d=det3(a,b,c);if(fabs(d)<1e-18)return invalid3();SebPoint center=mul3(add3(add3(mul3(cross3(b,c),qa),mul3(cross3(c,a),qb)),mul3(cross3(a,b),qc)),1.0/d);return (SebSphere){center,sqrt(dot3(sub3(center,p[0]),sub3(center,p[0]))) };
}
static int contains3(SebSphere s,SebPoint p){if(s.r<0)return 0;SebPoint d=sub3(p,s.c);return dot3(d,d)<=(s.r+1e-10)*(s.r+1e-10);}
static SebSphere fit3(const SebPoint *r,int m){SebSphere best=invalid3();int limit=1<<m;for(int mask=1;mask<limit;mask++){SebPoint q[4];int n=0;for(int i=0;i<m;i++)if(mask&(1<<i))q[n++]=r[i];if(n>4)continue;SebSphere s=through3(q,n);if(s.r<0)continue;int ok=1;for(int i=0;i<m;i++)if(!contains3(s,r[i])){ok=0;break;}if(ok&&(best.r<0||s.r<best.r-1e-12))best=s;}return best;}
static SebSphere welzl3(const SebPoint *p,int n,SebPoint *r,int m){if(n==0||m==4)return fit3(r,m);SebSphere s=welzl3(p,n-1,r,m);if(contains3(s,p[n-1]))return s;r[m]=p[n-1];return welzl3(p,n-1,r,m+1);}
int64_t smallest_enclosing_ball_3d(const double *input,size_t length,double *output,size_t capacity){
    if(!input||length<4||length>25||!isfinite(input[0])||input[0]<1||input[0]>8||input[0]!=floor(input[0]))return -1;int n=(int)input[0];if(length!=(size_t)(1+3*n))return -1;SebPoint p[8];for(int i=0;i<n;i++){p[i]=(SebPoint){input[1+3*i],input[2+3*i],input[3+3*i]};if(!isfinite(p[i].x)||!isfinite(p[i].y)||!isfinite(p[i].z)||fabs(p[i].x)>10||fabs(p[i].y)>10||fabs(p[i].z)>10)return -1;}
    for(int i=1;i<n;i++){SebPoint v=p[i];int j=i;while(j>0&&(p[j-1].x>v.x||(p[j-1].x==v.x&&(p[j-1].y>v.y||(p[j-1].y==v.y&&p[j-1].z>v.z))))){p[j]=p[j-1];j--;}p[j]=v;}SebPoint r[4];SebSphere s=welzl3(p,n,r,0);if(s.r<0||!isfinite(s.r))return -1;if(!output||capacity<4)return -2;output[0]=s.c.x;output[1]=s.c.y;output[2]=s.c.z;output[3]=s.r;return 4;
}
