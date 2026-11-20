module max_min_triangle_height_triangulation;

const int MIN_N = 3;
const int MAX_N = 5;
const usz MAX_LENGTH = 12;
const int DP_SIZE = 10;

struct Point { long x; long y; }
struct Score { long num; long den; }
struct Cell { Score minimum; int count; bool valid; int split; }
struct Triangle { int a; int b; int c; }
struct Triangles { Triangle[3] items; int count; }
struct Objective { Score minimum; int count; }

fn long abs64(long value) { return value < 0 ? -value : value; }
fn long gcd64(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a;
}
fn long orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
fn int compare(Score a, Score b) {
    long left = a.num*b.den;
    long right = b.num*a.den;
    return left < right ? -1 : left > right ? 1 : 0;
}
fn Score fraction(long num, long den) {
    long d = gcd64(num, den);
    return Score{num/d, den/d};
}
fn Score triangle_score(Point* points, int n, int a, int b, int c) {
    Point p=points[a%n], q=points[b%n], r=points[c%n];
    long area=abs64(orient(p,q,r));
    long lengths[3] = {
        (p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y),
        (q.x-r.x)*(q.x-r.x)+(q.y-r.y)*(q.y-r.y),
        (r.x-p.x)*(r.x-p.x)+(r.y-p.y)*(r.y-p.y)
    };
    Score best=fraction(area*area,lengths[0]);
    for (int i=1;i<3;i++) {
        Score candidate=fraction(area*area,lengths[i]);
        if (compare(candidate,best)<0) best=candidate;
    }
    return best;
}
fn Objective join(Cell left, Cell right, Score triangle) {
    Objective out=Objective{triangle,1};
    Cell[2] children={left,right};
    for (int i=0;i<2;i++) {
        if (!children[i].valid) continue;
        int cmp=compare(children[i].minimum,out.minimum);
        if (cmp<0) { out.minimum=children[i].minimum; out.count=children[i].count; }
        else if (cmp==0) out.count+=children[i].count;
    }
    return out;
}
fn bool better(Objective candidate, Objective current) {
    int cmp=compare(candidate.minimum,current.minimum);
    return cmp>0 || (cmp==0 && candidate.count<current.count);
}
fn Objective evaluate(Point* points, int n, Triangles triangles) {
    Triangle first=triangles.items[0];
    Objective out=Objective{triangle_score(points,n,first.a,first.b,first.c),1};
    for (int i=1;i<triangles.count;i++) {
        Triangle t=triangles.items[i];
        Score score=triangle_score(points,n,t.a,t.b,t.c);
        int cmp=compare(score,out.minimum);
        if (cmp<0) { out.minimum=score; out.count=1; }
        else if (cmp==0) out.count++;
    }
    return out;
}
fn void collect(int start, int end, Cell* table, int n, Triangles* out) {
    if (end-start<2) return;
    int middle=table[start*DP_SIZE+end].split;
    out.items[out.count]=Triangle{start%n,middle%n,end%n};
    out.count++;
    collect(start,middle,table,n,out);
    collect(middle,end,table,n,out);
}
fn bool has_edge(Triangles triangles, int left, int right) {
    for (int i=0;i<triangles.count;i++) {
        Triangle t=triangles.items[i];
        int[3][2] pairs={{t.a,t.b},{t.b,t.c},{t.c,t.a}};
        for (int j=0;j<3;j++) {
            int a=pairs[j][0], b=pairs[j][1];
            if (a>b) { int temp=a; a=b; b=temp; }
            if (a==left && b==right) return true;
        }
    }
    return false;
}
fn long solve(Point* points, int n) {
    Cell[DP_SIZE*DP_SIZE] table;
    for (int i=0;i<DP_SIZE*DP_SIZE;i++) table[i]=Cell{Score{0,1},0,false,-1};
    for (int span=2;span<=n-2;span++) {
        for (int start=0;start<n;start++) {
            int end=start+span;
            Objective best=Objective{Score{0,1},0};
            int best_middle=-1;
            for (int middle=start+1;middle<end;middle++) {
                Objective candidate=join(table[start*DP_SIZE+middle],table[middle*DP_SIZE+end],
                                         triangle_score(points,n,start,middle,end));
                if (best_middle<0 || better(candidate,best)) { best=candidate; best_middle=middle; }
            }
            table[start*DP_SIZE+end]=Cell{best.minimum,best.count,true,best_middle};
        }
    }
    Triangles current=Triangles{.count=0};
    for (int middle=1;middle<n-1;middle++) {
        current.items[current.count]=Triangle{0,middle,middle+1};
        current.count++;
    }
    Objective current_value=evaluate(points,n,current);
    int improvements=0;
    while (true) {
        bool changed=false;
        for (int left=0;left<n && !changed;left++) {
            for (int right=left+2;right<n;right++) {
                if (left==0 && right==n-1) continue;
                if (has_edge(current,left,right)) continue;
                Triangles candidate=Triangles{.count=0};
                collect(left,right,&table[0],n,&candidate);
                collect(right,left+n,&table[0],n,&candidate);
                Objective value=evaluate(points,n,candidate);
                if (better(value,current_value)) {
                    current=candidate; current_value=value; improvements++;
                    if (improvements>30) return -1;
                    changed=true; break;
                }
            }
        }
        if (!changed) return current_value.minimum.num*513+current_value.minimum.den;
    }
}

fn long max_min_triangle_height_triangulation(long* input, usz length)
    @export("max_min_triangle_height_triangulation") {
    if (input==null || length<1 || length>MAX_LENGTH) return -1;
    if (input[0]<MIN_N || input[0]>MAX_N) return -1;
    int n=(int)input[0];
    if (length!=(usz)(1+2*n)) return -1;
    Point[MAX_N] points;
    for (int i=0;i<n;i++) {
        points[i]=Point{input[1+2*i],input[2+2*i]};
        if (points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8) return -1;
        for (int j=0;j<i;j++)
            if (points[i].x==points[j].x && points[i].y==points[j].y) return -1;
    }
    long area2=0;
    for (int i=0;i<n;i++) { int next=(i+1)%n; area2+=points[i].x*points[next].y-points[i].y*points[next].x; }
    if (area2<=0) return -1;
    for (int a=0;a<n;a++) for (int b=a+1;b<n;b++) for (int c=b+1;c<n;c++)
        if (orient(points[a],points[b],points[c])==0) return -1;
    for (int edge=0;edge<n;edge++) {
        int next=(edge+1)%n;
        for (int v=0;v<n;v++)
            if (v!=edge && v!=next && orient(points[edge],points[next],points[v])<=0) return -1;
    }
    return solve(&points[0],n);
}
