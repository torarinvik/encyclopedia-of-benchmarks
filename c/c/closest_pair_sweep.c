#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x,y; } Point;
typedef struct { Point point; int left,right,height; } Node;

static int point_less(Point p, Point q) {
    return p.x<q.x || (p.x==q.x && p.y<q.y);
}
static int key_compare(Point a, Point b) {
    if (a.y!=b.y) return a.y<b.y ? -1 : 1;
    return a.x==b.x ? 0 : a.x<b.x ? -1 : 1;
}
static int height(Node *nodes, int i) { return i<0 ? 0 : nodes[i].height; }
static void fix(Node *nodes, int i) {
    int left=height(nodes,nodes[i].left), right=height(nodes,nodes[i].right);
    nodes[i].height=1+(left>right ? left : right);
}
static int rotate_right(Node *nodes, int i) {
    int j=nodes[i].left; nodes[i].left=nodes[j].right; nodes[j].right=i;
    fix(nodes,i); fix(nodes,j); return j;
}
static int rotate_left(Node *nodes, int i) {
    int j=nodes[i].right; nodes[i].right=nodes[j].left; nodes[j].left=i;
    fix(nodes,i); fix(nodes,j); return j;
}
static int balance(Node *nodes, int i) {
    fix(nodes,i);
    int delta=height(nodes,nodes[i].left)-height(nodes,nodes[i].right);
    if (delta>1) {
        int j=nodes[i].left;
        if (height(nodes,nodes[j].left)<height(nodes,nodes[j].right)) nodes[i].left=rotate_left(nodes,j);
        return rotate_right(nodes,i);
    }
    if (delta< -1) {
        int j=nodes[i].right;
        if (height(nodes,nodes[j].right)<height(nodes,nodes[j].left)) nodes[i].right=rotate_right(nodes,j);
        return rotate_left(nodes,i);
    }
    return i;
}
static int insert(Node *nodes, int root, int index) {
    if (root<0) return index;
    if (key_compare(nodes[index].point,nodes[root].point)<0) nodes[root].left=insert(nodes,nodes[root].left,index);
    else nodes[root].right=insert(nodes,nodes[root].right,index);
    return balance(nodes,root);
}
static int erase(Node *nodes, int root, Point key) {
    if (root<0) return -1;
    int order=key_compare(key,nodes[root].point);
    if (order<0) nodes[root].left=erase(nodes,nodes[root].left,key);
    else if (order>0) nodes[root].right=erase(nodes,nodes[root].right,key);
    else {
        if (nodes[root].left<0) return nodes[root].right;
        if (nodes[root].right<0) return nodes[root].left;
        int next=nodes[root].right;
        while (nodes[next].left>=0) next=nodes[next].left;
        nodes[root].point=nodes[next].point;
        nodes[root].right=erase(nodes,nodes[root].right,nodes[next].point);
    }
    return balance(nodes,root);
}
static void range_min(const Node *nodes, int root, Point query, int64_t lower, int64_t upper, int64_t *best) {
    if (root<0) return;
    Point p=nodes[root].point;
    if (p.y>=lower) range_min(nodes,nodes[root].left,query,lower,upper,best);
    if (p.y>=lower && p.y<=upper) {
        int64_t dx=query.x-p.x, dy=query.y-p.y, distance=dx*dx+dy*dy;
        if (distance<*best) *best=distance;
    }
    if (p.y<=upper) range_min(nodes,nodes[root].right,query,lower,upper,best);
}

int64_t closest_pair_sweep(const int64_t *input, size_t length) {
    if (!input || length<5 || length>130 || input[0]<2 || input[0]>64) return -1;
    size_t n=(size_t)input[0];
    if (length!=1+2*n) return -1;
    Point points[64]; Node nodes[64];
    for (size_t i=0; i<n; ++i) {
        int64_t x=input[1+2*i],y=input[2+2*i];
        if (x< -1000 || x>1000 || y< -1000 || y>1000) return -1;
        points[i]=(Point){x,y};
    }
    Point scratch[64];
    for (size_t width=1; width<n; width*=2) {
        for (size_t begin=0; begin<n; begin+=2*width) {
            size_t middle=begin+width<n ? begin+width : n;
            size_t end=begin+2*width<n ? begin+2*width : n;
            size_t i=begin, j=middle;
            for (size_t k=begin; k<end; ++k) {
                if (j==end || (i<middle && !point_less(points[j],points[i]))) scratch[k]=points[i++];
                else scratch[k]=points[j++];
            }
        }
        for (size_t i=0; i<n; ++i) points[i]=scratch[i];
    }
    for (size_t i=1; i<n; ++i) if (points[i].x==points[i-1].x && points[i].y==points[i-1].y) return 0;
    int root=-1;
    size_t left=0;
    int64_t best=8000001;
    for (size_t i=0; i<n; ++i) {
        Point p=points[i];
        while (left<i && (p.x-points[left].x)*(p.x-points[left].x)>best) root=erase(nodes,root,points[left++]);
        int64_t lo=0,hi=3000;
        while (lo<hi) { int64_t middle=(lo+hi+1)/2; if (middle*middle<=best) lo=middle; else hi=middle-1; }
        range_min(nodes,root,p,p.y-lo,p.y+lo,&best);
        nodes[i]=(Node){p,-1,-1,1};
        root=insert(nodes,root,(int)i);
    }
    return best;
}
