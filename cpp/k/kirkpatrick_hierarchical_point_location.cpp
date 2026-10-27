#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_LEVELS 4
#define MAX_FACES 8
#define MAX_INPUT 268

static int64_t cross(int64_t ax,int64_t ay,int64_t bx,int64_t by,int64_t cx,int64_t cy){
    return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax);
}
static int on_segment(int64_t ax,int64_t ay,int64_t bx,int64_t by,int64_t px,int64_t py){
    return cross(ax,ay,bx,by,px,py)==0&&px>=(ax<bx?ax:bx)&&px<=(ax>bx?ax:bx)&&py>=(ay<by?ay:by)&&py<=(ay>by?ay:by);
}
static int point_inside(int64_t qx,int64_t qy,const int64_t t[3],const int64_t xy[MAX_VERTICES][2]){
    int64_t ax=xy[t[0]][0],ay=xy[t[0]][1],bx=xy[t[1]][0],by=xy[t[1]][1],cx=xy[t[2]][0],cy=xy[t[2]][1];
    return cross(ax,ay,bx,by,qx,qy)>0&&cross(bx,by,cx,cy,qx,qy)>0&&cross(cx,cy,ax,ay,qx,qy)>0;
}
static int point_boundary(int64_t qx,int64_t qy,const int64_t t[3],const int64_t xy[MAX_VERTICES][2]){
    for(int e=0;e<3;++e){int a=(int)t[e],b=(int)t[(e+1)%3];if(on_segment(xy[a][0],xy[a][1],xy[b][0],xy[b][1],qx,qy))return 1;}return 0;
}
static int segment_intersects(int64_t ax,int64_t ay,int64_t bx,int64_t by,int64_t cx,int64_t cy,int64_t dx,int64_t dy){
    int64_t o1=cross(ax,ay,bx,by,cx,cy),o2=cross(ax,ay,bx,by,dx,dy),o3=cross(cx,cy,dx,dy,ax,ay),o4=cross(cx,cy,dx,dy,bx,by);
    if(o1==0&&on_segment(ax,ay,bx,by,cx,cy))return 1;if(o2==0&&on_segment(ax,ay,bx,by,dx,dy))return 1;
    if(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))return 1;if(o4==0&&on_segment(cx,cy,dx,dy,bx,by))return 1;
    return o1*o2<0&&o3*o4<0;
}
static int closed_inside(const int64_t p[2],const int64_t t[3],const int64_t xy[MAX_VERTICES][2]){
    for(int e=0;e<3;++e){int a=(int)t[e],b=(int)t[(e+1)%3];if(cross(xy[a][0],xy[a][1],xy[b][0],xy[b][1],p[0],p[1])<0)return 0;}return 1;
}
static int triangles_intersect(const int64_t a[3],const int64_t b[3],const int64_t xy[MAX_VERTICES][2]){
    for(int i=0;i<3;++i){int64_t p[2]={xy[a[i]][0],xy[a[i]][1]};if(closed_inside(p,b,xy))return 1;}
    for(int i=0;i<3;++i){int64_t p[2]={xy[b[i]][0],xy[b[i]][1]};if(closed_inside(p,a,xy))return 1;}
    for(int i=0;i<3;++i)for(int j=0;j<3;++j){int ai=(int)a[i],an=(int)a[(i+1)%3],bi=(int)b[j],bn=(int)b[(j+1)%3];
        if(segment_intersects(xy[ai][0],xy[ai][1],xy[an][0],xy[an][1],xy[bi][0],xy[bi][1],xy[bn][0],xy[bn][1]))return 1;}
    return 0;
}
static void put64(uint8_t *out,size_t pos,int64_t value){uint64_t bits=(uint64_t)value;for(size_t j=0;j<8;++j){out[pos+j]=(uint8_t)(bits&255U);bits>>=8;}}

extern "C" int64_t kirkpatrick_hierarchical_point_location(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<14||length>MAX_INPUT)return -1;
    int64_t nv=input[0],nl=input[1],qx=input[2],qy=input[3];
    if(nv<3||nv>MAX_VERTICES||nl<1||nl>MAX_LEVELS||qx< -1000||qx>1000||qy< -1000||qy>1000)return -1;
    int64_t xy[MAX_VERTICES][2]={{0}},faces[MAX_LEVELS][MAX_FACES][3]={{{0}}};
    int64_t face_count[MAX_LEVELS]={0},candidate_count[MAX_LEVELS][MAX_FACES]={{0}},candidate_ids[MAX_LEVELS][MAX_FACES][MAX_FACES]={{{0}}};
    size_t pos=4;
    for(int v=0;v<nv;++v){xy[v][0]=input[pos++];xy[v][1]=input[pos++];if(xy[v][0]<-1000||xy[v][0]>1000||xy[v][1]<-1000||xy[v][1]>1000)return -1;}
    for(int level=0;level<nl;++level){
        if(pos>=length)return -1;int64_t count=input[pos++];if(count<1||count>MAX_FACES||(level==0&&count!=1))return -1;face_count[level]=count;
        for(int f=0;f<count;++f){if(pos+3>length)return -1;for(int k=0;k<3;++k){faces[level][f][k]=input[pos++];if(faces[level][f][k]<0||faces[level][f][k]>=nv)return -1;}
            if(faces[level][f][0]==faces[level][f][1]||faces[level][f][0]==faces[level][f][2]||faces[level][f][1]==faces[level][f][2])return -1;
            int64_t *t=faces[level][f];if(cross(xy[t[0]][0],xy[t[0]][1],xy[t[1]][0],xy[t[1]][1],xy[t[2]][0],xy[t[2]][1])<=0)return -1;
        }
        if(level+1<nl)for(int f=0;f<count;++f){
            if(pos>=length)return -1;int64_t cc=input[pos++];if(cc<1||cc>MAX_FACES||pos+(size_t)cc>length)return -1;candidate_count[level][f]=cc;
            for(int j=0;j<cc;++j){candidate_ids[level][f][j]=input[pos++];if(candidate_ids[level][f][j]<0||candidate_ids[level][f][j]>=MAX_FACES||(j&&candidate_ids[level][f][j]<=candidate_ids[level][f][j-1]))return -1;}
        }
    }
    if(pos!=length)return -1;
    for(int level=0;level+1<nl;++level)for(int f=0;f<face_count[level];++f)for(int j=0;j<candidate_count[level][f];++j){
        int64_t child=candidate_ids[level][f][j];if(child>=face_count[level+1]||!triangles_intersect(faces[level][f],faces[level+1][child],xy))return -1;
    }
    for(int level=0;level<nl;++level){int hits=0;for(int f=0;f<face_count[level];++f){if(point_boundary(qx,qy,faces[level][f],xy))return -1;if(point_inside(qx,qy,faces[level][f],xy))++hits;}if(hits!=1)return -1;}
    int64_t face=0,predicates=1;
    for(int level=0;level+1<nl;++level){int64_t found=-1;for(int j=0;j<candidate_count[level][face];++j){int64_t child=candidate_ids[level][face][j];++predicates;if(point_inside(qx,qy,faces[level+1][child],xy)){found=child;break;}}
        if(found<0)return -1;face=found;
    }
    if(!output||capacity<16)return -2;uint8_t staged[16];put64(staged,0,face);put64(staged,8,predicates);for(size_t i=0;i<16;++i)output[i]=staged[i];return 16;
}
