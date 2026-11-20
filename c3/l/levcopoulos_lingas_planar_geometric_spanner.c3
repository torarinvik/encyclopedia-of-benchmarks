module levcopoulos_lingas_planar_geometric_spanner;

const int MAX_N=8, MAX_E=18, MAX_F=16, MAX_D=14, MAX_STACK=64, MAX_INPUT=55;

struct State {
    int n,m,face_count,contour_len,stack_len;
    int[MAX_N] degree,tree_degree;
    long[MAX_N] x,y;
    long[MAX_E] eu,ev;
    long[MAX_F] fa,fb,fc;
    long[MAX_N][MAX_N] rotation,tree_rotation;
    long[MAX_D] contour_u,contour_v;
    long[MAX_STACK] stack_u,stack_v;
    double[MAX_N][MAX_N] weight;
    bool[MAX_N] hull;
    bool[MAX_N][MAX_N] tree,kept;
}

fn long orient(State* s,long a,long b,long c) {
    return (s.x[b]-s.x[a])*(s.y[c]-s.y[a])-(s.y[b]-s.y[a])*(s.x[c]-s.x[a]);
}
fn long incircle(State* s,long a,long b,long c,long p) {
    long ax=s.x[a]-s.x[p],ay=s.y[a]-s.y[p],bx=s.x[b]-s.x[p],by=s.y[b]-s.y[p],cx=s.x[c]-s.x[p],cy=s.y[c]-s.y[p];
    return (ax*ax+ay*ay)*(bx*cy-by*cx)-(bx*bx+by*by)*(ax*cy-ay*cx)+(cx*cx+cy*cy)*(ax*by-ay*bx);
}
fn long dist2(State* s,long a,long b) { long dx=s.x[a]-s.x[b],dy=s.y[a]-s.y[b]; return dx*dx+dy*dy; }
fn void sort3(long* a,long* b,long* c) {
    long t; if(*a>*b){t=*a;*a=*b;*b=t;} if(*b>*c){t=*b;*b=*c;*c=t;} if(*a>*b){t=*a;*a=*b;*b=t;}
}
fn bool is_face(State* s,long a,long b,long c) {
    sort3(&a,&b,&c);
    for(int i=0;i<s.face_count;i++) if(s.fa[i]==a && s.fb[i]==b && s.fc[i]==c) return true;
    return false;
}
fn int angle_half(long dx,long dy) { return dy>0 || (dy==0 && dx>=0) ? 0 : 1; }
fn bool angle_less(State* s,long origin,long a,long b) {
    long ax=s.x[a]-s.x[origin],ay=s.y[a]-s.y[origin],bx=s.x[b]-s.x[origin],by=s.y[b]-s.y[origin];
    int ah=angle_half(ax,ay),bh=angle_half(bx,by); if(ah!=bh) return ah<bh;
    long cross=ax*by-ay*bx; if(cross!=0) return cross>0; return a<b;
}
fn bool add_rotation(State* s,long a,long b) {
    if(s.degree[a]>=MAX_N || s.degree[b]>=MAX_N) return false;
    s.rotation[a][s.degree[a]]=b;s.degree[a]++;s.rotation[b][s.degree[b]]=a;s.degree[b]++;return true;
}
fn void sort_rotations(State* s) {
    for(long v=0;v<s.n;v++) for(int i=1;i<s.degree[v];i++) {
        long key=s.rotation[v][i];int pos=i;
        while(pos>0 && angle_less(s,v,key,s.rotation[v][pos-1])) { s.rotation[v][pos]=s.rotation[v][pos-1];pos--; }
        s.rotation[v][pos]=key;
    }
}
fn bool cw_next(State* s,long u,long v,long* out_u,long* out_v) {
    for(int i=0;i<s.degree[v];i++) if(s.rotation[v][i]==u) {
        *out_u=v;*out_v=s.rotation[v][(i+s.degree[v]-1)%s.degree[v]];return true;
    }
    return false;
}
fn bool cw_tree_next(State* s,long u,long v,long* out_u,long* out_v) {
    for(int i=0;i<s.tree_degree[v];i++) if(s.tree_rotation[v][i]==u) {
        *out_u=v;*out_v=s.tree_rotation[v][(i+s.tree_degree[v]-1)%s.tree_degree[v]];return true;
    }
    return false;
}
fn int contour_find(State* s,long u,long v) {
    for(int i=0;i<s.contour_len;i++) if(s.contour_u[i]==u && s.contour_v[i]==v) return i;
    return -1;
}
fn void canonicalize(State* s) {
    if(s.contour_len==0) return;
    int first=0;for(int i=1;i<s.contour_len;i++)
        if(s.contour_u[i]<s.contour_u[first] || (s.contour_u[i]==s.contour_u[first] && s.contour_v[i]<s.contour_v[first])) first=i;
    long[MAX_D] tu=zeroed,tv=zeroed;
    for(int i=0;i<s.contour_len;i++){int at=(first+i)%s.contour_len;tu[i]=s.contour_u[at];tv[i]=s.contour_v[at];}
    for(int i=0;i<s.contour_len;i++){s.contour_u[i]=tu[i];s.contour_v[i]=tv[i];}
}
fn bool eligible(State* s,long u,long v) {
    int at=contour_find(s,u,v);if(at<0 || s.hull[v] || s.contour_len<3)return false;
    int next=(at+1)%s.contour_len;long nu,nv;
    return cw_next(s,u,v,&nu,&nv) && s.contour_u[next]==nu && s.contour_v[next]==nv && is_face(s,u,v,nv);
}
fn bool push_if_eligible(State* s,long u,long v) {
    if(!eligible(s,u,v))return true;if(s.stack_len>=MAX_STACK)return false;
    s.stack_u[s.stack_len]=u;s.stack_v[s.stack_len]=v;s.stack_len++;return true;
}

fn bool parse(State* s,long* input,usz length) {
    if(input==null || length<14 || length>MAX_INPUT)return false;
    long n64=input[0];if(n64<3 || n64>MAX_N)return false;s.n=(int)n64;
    usz m_at=1+2*(usz)s.n;if(length<=m_at)return false;
    long m64=input[m_at];if(m64<3 || m64>MAX_E || length!=m_at+1+2*(usz)m64)return false;s.m=(int)m64;
    for(int i=0;i<s.n;i++) {
        s.x[i]=input[1+2*i];s.y[i]=input[2+2*i];
        if(s.x[i]< -10 || s.x[i]>10 || s.y[i]< -10 || s.y[i]>10)return false;
        for(int j=0;j<i;j++)if(s.x[i]==s.x[j] && s.y[i]==s.y[j])return false;
    }
    for(long a=0;a<s.n;a++)for(long b=a+1;b<s.n;b++)for(long c=b+1;c<s.n;c++)if(orient(s,a,b,c)==0)return false;
    for(long a=0;a<s.n;a++)for(long b=a+1;b<s.n;b++)for(long c=b+1;c<s.n;c++)for(long d=c+1;d<s.n;d++)if(incircle(s,a,b,c,d)==0)return false;
    bool[MAX_N][MAX_N] supplied=zeroed,expected=zeroed;
    for(int i=0;i<s.m;i++) {
        long u=input[m_at+1+2*i],v=input[m_at+2+2*i];
        if(u<0 || v<=u || v>=s.n)return false;
        if(i>0 && (u<s.eu[i-1] || (u==s.eu[i-1] && v<=s.ev[i-1])))return false;
        s.eu[i]=u;s.ev[i]=v;supplied[u][v]=true;supplied[v][u]=true;
    }
    for(long a0=0;a0<s.n;a0++)for(long b0=a0+1;b0<s.n;b0++)for(long c0=b0+1;c0<s.n;c0++) {
        long a=a0,b=b0,c=c0;if(orient(s,a,b,c)<0){long t=b;b=c;c=t;}
        bool empty=true;for(long p=0;p<s.n;p++)if(p!=a && p!=b && p!=c && incircle(s,a,b,c,p)>0)empty=false;
        if(empty) {
            if(s.face_count>=MAX_F)return false;
            long fa=a,fb=b,fc=c;sort3(&fa,&fb,&fc);
            s.fa[s.face_count]=fa;s.fb[s.face_count]=fb;s.fc[s.face_count]=fc;s.face_count++;
            expected[a][b]=true;expected[b][a]=true;expected[a][c]=true;expected[c][a]=true;expected[b][c]=true;expected[c][b]=true;
        }
    }
    for(long a=0;a<s.n;a++)for(long b=a+1;b<s.n;b++)if(supplied[a][b]!=expected[a][b])return false;
    for(long a=0;a<s.n;a++)for(long b=a+1;b<s.n;b++) {
        bool positive=false,negative=false;
        for(long p=0;p<s.n;p++)if(p!=a && p!=b){long side=orient(s,a,b,p);positive=positive || side>0;negative=negative || side<0;}
        if(!(positive && negative)){s.hull[a]=true;s.hull[b]=true;}
    }
    for(int i=0;i<s.m;i++)if(!add_rotation(s,s.eu[i],s.ev[i]))return false;
    sort_rotations(s);return true;
}

fn bool build_tree(State* s) {
    int[MAX_E] order=zeroed;for(int i=0;i<s.m;i++)order[i]=i;
    for(int i=1;i<s.m;i++) {
        int key=order[i],pos=i;
        while(pos>0) {
            int prev=order[pos-1];long pd=dist2(s,s.eu[prev],s.ev[prev]),kd=dist2(s,s.eu[key],s.ev[key]);
            if(pd<kd || (pd==kd && (s.eu[prev]<s.eu[key] || (s.eu[prev]==s.eu[key] && s.ev[prev]<=s.ev[key]))))break;
            order[pos]=prev;pos--;
        }
        order[pos]=key;
    }
    long[MAX_N] parent=zeroed,size=zeroed;for(int i=0;i<s.n;i++){parent[i]=i;size[i]=1;}
    int chosen=0;
    for(int rank=0;rank<s.m;rank++) {
        int e=order[rank];long u=s.eu[e],v=s.ev[e],a=u,b=v;
        while(parent[a]!=a){parent[a]=parent[parent[a]];a=parent[a];}
        while(parent[b]!=b){parent[b]=parent[parent[b]];b=parent[b];}
        if(a==b)continue;if(size[a]<size[b]){long t=a;a=b;b=t;}parent[b]=a;size[a]+=size[b];
        s.tree[u][v]=true;s.tree[v][u]=true;s.kept[u][v]=true;s.kept[v][u]=true;
        s.tree_rotation[u][s.tree_degree[u]]=v;s.tree_degree[u]++;s.tree_rotation[v][s.tree_degree[v]]=u;s.tree_degree[v]++;chosen++;
    }
    if(chosen!=s.n-1)return false;
    for(long v=0;v<s.n;v++)for(int i=1;i<s.tree_degree[v];i++) {
        long key=s.tree_rotation[v][i];int pos=i;
        while(pos>0 && angle_less(s,v,key,s.tree_rotation[v][pos-1])){s.tree_rotation[v][pos]=s.tree_rotation[v][pos-1];pos--;}
        s.tree_rotation[v][pos]=key;
    }
    for(int i=0;i<s.m;i++){long u=s.eu[i],v=s.ev[i];double d=math.sqrt((double)dist2(s,u,v));s.weight[u][v]=d;s.weight[v][u]=d;}
    long fu=MAX_N,fv=MAX_N;
    for(long u=0;u<s.n;u++)for(long v=0;v<s.n;v++)if(s.tree[u][v] && (u<fu || (u==fu && v<fv))){fu=u;fv=v;}
    if(fu==MAX_N)return false;s.contour_u[0]=fu;s.contour_v[0]=fv;s.contour_len=1;
    int expected_darts=2*(s.n-1);
    while(s.contour_len<expected_darts) {
        int last=s.contour_len-1;long nu,nv;if(!cw_tree_next(s,s.contour_u[last],s.contour_v[last],&nu,&nv))return false;
        if(nu==fu && nv==fv)break;
        for(int i=0;i<s.contour_len;i++)if(s.contour_u[i]==nu && s.contour_v[i]==nv)return false;
        s.contour_u[s.contour_len]=nu;s.contour_v[s.contour_len]=nv;s.contour_len++;
    }
    if(s.contour_len!=expected_darts)return false;long cu,cv;
    return cw_tree_next(s,s.contour_u[s.contour_len-1],s.contour_v[s.contour_len-1],&cu,&cv) && cu==fu && cv==fv;
}

fn bool run_algorithm(State* s,long* absorbed_out,long* shortcut_out) {
    for(int i=0;i<s.contour_len;i++)if(!push_if_eligible(s,s.contour_u[i],s.contour_v[i]))return false;
    long absorbed=0;int steps=0;
    while(s.stack_len>0 && steps<2*MAX_E) {
        s.stack_len--;long v=s.stack_u[s.stack_len],w=s.stack_v[s.stack_len];if(!eligible(s,v,w))continue;
        int at=contour_find(s,v,w),next_at=(at+1)%s.contour_len;long u=s.contour_v[next_at];
        double path=s.weight[v][w]+s.weight[w][u],direct=math.sqrt((double)dist2(s,v,u));
        if(path>2.0*direct){s.kept[v][u]=true;s.kept[u][v]=true;}else s.weight[v][u]=path;
        if(next_at==0) {
            for(int i=0;i+1<s.contour_len;i++){s.contour_u[i]=s.contour_u[i+1];s.contour_v[i]=s.contour_v[i+1];}
            s.contour_len--;s.contour_u[s.contour_len-1]=v;s.contour_v[s.contour_len-1]=u;
        } else {
            s.contour_u[at]=v;s.contour_v[at]=u;
            for(int i=next_at;i+1<s.contour_len;i++){s.contour_u[i]=s.contour_u[i+1];s.contour_v[i]=s.contour_v[i+1];}
            s.contour_len--;
        }
        canonicalize(s);absorbed++;steps++;
        int ci=contour_find(s,v,u);if(ci<0)return false;
        if(!push_if_eligible(s,v,u))return false;
        int li=(ci+s.contour_len-1)%s.contour_len;if(!push_if_eligible(s,s.contour_u[li],s.contour_v[li]))return false;
    }
    if(steps>=2*MAX_E && s.stack_len>0)return false;
    long edges=0;for(int u=0;u<s.n;u++)for(int v=u+1;v<s.n;v++)if(s.kept[u][v])edges++;
    *absorbed_out=absorbed;*shortcut_out=edges-(s.n-1);return true;
}
fn void store_i64_le(char* output,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){output[offset+b]=(char)(bits&255);bits>>=8;}}

fn long levcopoulos_lingas_planar_geometric_spanner(long* input,usz length,char* output,usz capacity)
        @export("levcopoulos_lingas_planar_geometric_spanner") {
    if(input==null || length<14 || length>MAX_INPUT)return -1;
    State s=zeroed;if(!parse(&s,input,length) || !build_tree(&s))return -1;
    long absorbed=0,shortcuts=0;if(!run_algorithm(&s,&absorbed,&shortcuts))return -1;
    long[3+2*MAX_E] words=zeroed;usz count=3;words[0]=absorbed;words[1]=shortcuts;
    for(int u=0;u<s.n;u++)for(int v=u+1;v<s.n;v++)if(s.kept[u][v]){words[count]=u;words[count+1]=v;count+=2;words[2]++;}
    usz bytes=count*8;if(output==null || capacity<bytes)return -2;
    for(usz i=0;i<count;i++)store_i64_le(output,i*8,words[i]);return (long)bytes;
}
