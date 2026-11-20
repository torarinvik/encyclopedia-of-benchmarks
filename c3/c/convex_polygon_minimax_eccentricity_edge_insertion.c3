module convex_polygon_minimax_eccentricity_edge_insertion;

const int MIN_N=3, MAX_N=6, MAX_LEN=14, MAX_TRI=4, MAX_ALL=14, MAX_DIAG=9, MAX_TRIPLES=20;
struct Point { long x; long y; }
struct Triangle { int a; int b; int c; }
struct Triangulation { Triangle[MAX_TRI] triangles; int count; ulong edges; }
struct Fraction { long num; long den; }
struct Metrics { Fraction maximum; ulong worst; }

fn long orient(Point a,Point b,Point c){return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);}
fn long abs64(long x){return x<0?-x:x;}
fn long gcd64(long a,long b){while(b!=0){long r=a%b;a=b;b=r;}return a;}
fn Fraction frac(long n,long d){long g=gcd64(n,d);return Fraction{n/g,d/g};}
fn int cmp(Fraction a,Fraction b){long x=a.num*b.den,y=b.num*a.den;return x<y?-1:x>y?1:0;}
fn ulong edge_bit(int a,int b){int lo=a<b?a:b,hi=a<b?b:a;return 1ul<<(lo*MAX_N+hi);}
fn bool proper_cross(Point* p,int a,int b,int c,int d){return orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d])<0&&orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b])<0;}
fn bool inside_triangle(Point* p,Triangle t,int v){long dir=orient(p[t.a],p[t.b],p[t.c]);return orient(p[t.a],p[t.b],p[v])*dir>0&&orient(p[t.b],p[t.c],p[v])*dir>0&&orient(p[t.c],p[t.a],p[v])*dir>0;}
fn Fraction triangle_score(Point* p,Triangle t,long* sides){
    Point a=p[t.a],b=p[t.b],c=p[t.c];
    sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y);sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y);sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y);
    int k=0;if(sides[1]>sides[k])k=1;if(sides[2]>sides[k])k=2;long other=sides[0]+sides[1]+sides[2]-sides[k];if(sides[k]<=other)return Fraction{0,1};
    long area=abs64(orient(a,b,c)),diff=sides[k]-other;return frac(sides[k]*diff*diff,16*area*area);
}
fn int triangle_id(int a,int b,int c,int n){int id=0;for(int x=0;x<n;x++)for(int y=x+1;y<n;y++)for(int z=y+1;z<n;z++){if(x==a&&y==b&&z==c)return id;id++;}return 0;}
fn Metrics evaluate(Point* p,int n,Triangulation t){Metrics m=Metrics{Fraction{0,1},0};for(int i=0;i<t.count;i++){long sides[3];Fraction s=triangle_score(p,t.triangles[i],&sides[0]);int c=cmp(s,m.maximum);ulong bit=1ul<<triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n);if(c>0){m.maximum=s;m.worst=bit;}else if(c==0)m.worst|=bit;}return m;}
fn bool improves(Metrics a,Metrics b){int c=cmp(a.maximum,b.maximum);return c<0||(c==0&&a.worst!=b.worst&&(a.worst&b.worst)==a.worst);}
fn int popcount64(ulong x){int n=0;while(x!=0){x&=x-1;n++;}return n;}
fn bool preferable(Metrics a,Metrics b){int c=cmp(a.maximum,b.maximum);if(c!=0)return c<0;int x=popcount64(a.worst),y=popcount64(b.worst);return x!=y?x<y:a.worst<b.worst;}
fn int enumerate(Point* p,int n,Triangulation* out){
    int da[MAX_DIAG],db[MAX_DIAG],m=0;for(int a=0;a<n;a++)for(int b=a+2;b<n;b++){if(a==0&&b==n-1)continue;da[m]=a;db[m]=b;m++;}
    ulong boundary=0;for(int a=0;a<n;a++)boundary|=edge_bit(a,(a+1)%n);int total=0;
    for(int mask=0;mask<(1<<m);mask++){int count=0;for(int i=0;i<m;i++)if((mask>>i)&1)count++;if(count!=n-3)continue;
        bool crossing=false;for(int i=0;i<m&&!crossing;i++)if((mask>>i)&1)for(int j=i+1;j<m;j++)if((mask>>j)&1&&proper_cross(p,da[i],db[i],da[j],db[j])){crossing=true;break;}if(crossing)continue;
        ulong edges=boundary;for(int i=0;i<m;i++)if((mask>>i)&1)edges|=edge_bit(da[i],db[i]);Triangle faces[MAX_TRI];int nf=0;
        for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++){if(!(edges&edge_bit(a,b))||!(edges&edge_bit(b,c))||!(edges&edge_bit(c,a)))continue;bool contains=false;for(int v=0;v<n;v++)if(v!=a&&v!=b&&v!=c&&inside_triangle(p,Triangle{a,b,c},v)){contains=true;break;}if(!contains&&nf<MAX_TRI){faces[nf]=Triangle{a,b,c};nf++;}}
        if(nf==n-2&&total<MAX_ALL){out[total].count=nf;out[total].edges=edges;for(int i=0;i<nf;i++)out[total].triangles[i]=faces[i];total++;}
    }return total;
}
fn int rank_score(Point* p,int n,Fraction target){Fraction seen[MAX_TRIPLES];int count=0;for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++){long sides[3];Fraction s=triangle_score(p,Triangle{a,b,c},&sides[0]);if(cmp(s,target)>=0)continue;bool duplicate=false;for(int i=0;i<count;i++)if(cmp(s,seen[i])==0){duplicate=true;break;}if(!duplicate){seen[count]=s;count++;}}return count+1;}
fn long solve(Point* p,int n){
    Triangulation all[MAX_ALL];int total=enumerate(p,n,&all[0]);Triangulation fan;fan.count=0;fan.edges=0;for(int k=1;k<n-1;k++){fan.triangles[fan.count]=Triangle{0,k,k+1};fan.count++;}for(int a=0;a<n;a++)fan.edges|=edge_bit(a,(a+1)%n);for(int k=2;k<n-1;k++)fan.edges|=edge_bit(0,k);
    int index=-1;for(int i=0;i<total;i++)if(all[i].edges==fan.edges){index=i;break;}if(index<0)return -1;Triangulation current=all[index];Metrics cm=evaluate(p,n,current);
    for(int step=0;step<MAX_ALL;step++){bool changed=false;for(int ti=0;ti<current.count&&!changed;ti++){Triangle t=current.triangles[ti];long sides[3];Fraction score=triangle_score(p,t,&sides[0]);if(cmp(score,cm.maximum)!=0||score.num==0)continue;int largest=0;if(sides[1]>sides[largest])largest=1;if(sides[2]>sides[largest])largest=2;int vertices[3]={t.a,t.b,t.c};
        for(int ap=0;ap<3&&!changed;ap++){if(sides[ap]!=sides[largest])continue;int q=vertices[ap],opp[2],used=0;for(int k=0;k<3;k++)if(k!=ap)opp[used++]=vertices[k];for(int s=0;s<n&&!changed;s++){ulong added=edge_bit(q,s);if(s==q||(current.edges&added)||!proper_cross(p,q,s,opp[0],opp[1]))continue;ulong retained=current.edges;for(int u=0;u<n;u++)for(int v=u+1;v<n;v++){ulong bit=edge_bit(u,v);if((retained&bit)&&proper_cross(p,q,s,u,v))retained&=~bit;}
            int selected=-1;Metrics sm=Metrics{Fraction{0,1},0};for(int ci=0;ci<total;ci++){if(!(all[ci].edges&added)||(all[ci].edges&retained)!=retained)continue;Metrics candidate=evaluate(p,n,all[ci]);if(!improves(candidate,cm))continue;if(selected<0||preferable(candidate,sm)){selected=ci;sm=candidate;}}if(selected>=0){current=all[selected];cm=sm;changed=true;}}
        }}if(!changed)break;}return rank_score(p,n,cm.maximum);
}

fn long convex_polygon_minimax_eccentricity_edge_insertion(long* input,usz length)
    @export("convex_polygon_minimax_eccentricity_edge_insertion") {
    if(input==null||length<1||length>MAX_LEN||input[0]<MIN_N||input[0]>MAX_N)return -1;int n=(int)input[0];if(length!=(usz)(1+2*n))return -1;Point p[MAX_N];
    for(int i=0;i<n;i++){p[i]=Point{input[1+2*i],input[2+2*i]};if(p[i].x < -4||p[i].x>4||p[i].y < -4||p[i].y>4)return -1;for(int j=0;j<i;j++)if(p[i].x==p[j].x&&p[i].y==p[j].y)return -1;}
    long area2=0;for(int i=0;i<n;i++){int j=(i+1)%n;area2+=p[i].x*p[j].y-p[i].y*p[j].x;}if(area2==0)return -1;int direction=area2>0?1:-1;
    for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)if(orient(p[a],p[b],p[c])==0)return -1;
    for(int e=0;e<n;e++){int j=(e+1)%n;for(int v=0;v<n;v++)if(v!=e&&v!=j&&direction*orient(p[e],p[j],p[v])<=0)return -1;}
    return solve(&p[0],n);
}
