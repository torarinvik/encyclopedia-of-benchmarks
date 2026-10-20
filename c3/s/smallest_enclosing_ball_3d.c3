module smallest_enclosing_ball_3d;
extern fn double sqrt(double v);
extern fn double fabs(double v);
struct Point { double x; double y; double z; }
struct Sphere { Point c; double r; }
Point sub(Point a,Point b){return {.x=a.x-b.x,.y=a.y-b.y,.z=a.z-b.z};}
Point add(Point a,Point b){return {.x=a.x+b.x,.y=a.y+b.y,.z=a.z+b.z};}
Point mul(Point a,double s){return {.x=a.x*s,.y=a.y*s,.z=a.z*s};}
double dot(Point a,Point b){return a.x*b.x+a.y*b.y+a.z*b.z;}
Point cross(Point a,Point b){return {.x=a.y*b.z-a.z*b.y,.y=a.z*b.x-a.x*b.z,.z=a.x*b.y-a.y*b.x};}
double det(Point a,Point b,Point c){return dot(a,cross(b,c));}
Sphere invalid(){return {.c={},.r=-1};}
Sphere through(Point* p,int n){if(n==1)return {.c=p[0],.r=0};if(n==2){Point c=mul(add(p[0],p[1]),0.5),d=sub(p[0],c);return {.c=c,.r=sqrt(dot(d,d))};}if(n==3){Point u=sub(p[1],p[0]),v=sub(p[2],p[0]),w=cross(u,v);double den=2*dot(w,w);if(den<1e-24)return invalid();Point off=mul(add(mul(cross(v,w),dot(u,u)),mul(cross(w,u),dot(v,v))),1/den),c=add(p[0],off),d=sub(c,p[0]);return {.c=c,.r=sqrt(dot(d,d))};}Point a=mul(sub(p[1],p[0]),2),b=mul(sub(p[2],p[0]),2),c=mul(sub(p[3],p[0]),2);double qa=dot(p[1],p[1])-dot(p[0],p[0]),qb=dot(p[2],p[2])-dot(p[0],p[0]),qc=dot(p[3],p[3])-dot(p[0],p[0]),d=det(a,b,c);if(fabs(d)<1e-18)return invalid();Point center=mul(add(add(mul(cross(b,c),qa),mul(cross(c,a),qb)),mul(cross(a,b),qc)),1/d),delta=sub(center,p[0]);return {.c=center,.r=sqrt(dot(delta,delta))};}
bool contains(Sphere s,Point p){if(s.r<0)return false;Point d=sub(p,s.c);return dot(d,d)<=(s.r+1e-10)*(s.r+1e-10);}
Sphere fit(Point* r,int m){Sphere best=invalid();for(int mask=1;mask<(1<<m);mask++){Point q[4];int n=0;for(int i=0;i<m;i++)if(mask&(1<<i))q[n++]=r[i];Sphere s=through(q,n);if(s.r<0)continue;bool ok=true;for(int i=0;i<m;i++)if(!contains(s,r[i]))ok=false;if(ok&&(best.r<0||s.r<best.r-1e-12))best=s;}return best;}
Sphere welzl(Point* p,int n,Point* r,int m){if(n==0||m==4)return fit(r,m);Sphere s=welzl(p,n-1,r,m);if(contains(s,p[n-1]))return s;r[m]=p[n-1];return welzl(p,n-1,r,m+1);}
fn long smallest_enclosing_ball_3d(double* input,usz length,double* output,usz capacity) @export("smallest_enclosing_ball_3d") {if(input==null||length<4||length>25)return -1;double raw=input[0];if(raw<1||raw>8||raw!=(double)(int)raw)return -1;int n=(int)raw;if(length!=(usz)(1+3*n))return -1;Point p[8];for(int i=0;i<n;i++){p[i]={.x=input[1+3*i],.y=input[2+3*i],.z=input[3+3*i]};if(p[i].x!=p[i].x||p[i].y!=p[i].y||p[i].z!=p[i].z||fabs(p[i].x)>10||fabs(p[i].y)>10||fabs(p[i].z)>10||p[i].x>1e308||p[i].y>1e308||p[i].z>1e308||p[i].x< -1e308||p[i].y< -1e308||p[i].z< -1e308)return -1;}for(int i=1;i<n;i++){Point v=p[i];int j=i;while(j>0&&(p[j-1].x>v.x||(p[j-1].x==v.x&&(p[j-1].y>v.y||(p[j-1].y==v.y&&p[j-1].z>v.z))))){p[j]=p[j-1];j--;}p[j]=v;}Point r[4];Sphere s=welzl(p,n,r,0);if(s.r<0||s.r>1e308)return -1;if(output==null||capacity<4)return -2;output[0]=s.c.x;output[1]=s.c.y;output[2]=s.c.z;output[3]=s.r;return 4;}
