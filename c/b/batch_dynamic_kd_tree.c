/* Bounded ParGeo-style logarithmic batch-dynamic point forest; see package README/LICENSE. */
#include <stddef.h>
#include <stdint.h>
#define BDK_MAX_INPUT 250

typedef struct { int id,left,right; int64_t minx,maxx,miny,maxy; } BdkNode;
static int bdk_less(int a,int b,int axis,const int64_t x[32],const int64_t y[32]){
    int64_t av=axis?y[a]:x[a],bv=axis?y[b]:x[b];
    if(av!=bv)return av<bv;
    int64_t aw=axis?x[a]:y[a],bw=axis?x[b]:y[b];
    return aw!=bw?aw<bw:a<b;
}
static int bdk_build(int ids[32],int lo,int hi,int depth,const int64_t x[32],const int64_t y[32],BdkNode nodes[32],int *used){
    if(lo>=hi)return -1;int axis=depth&1;
    for(int i=lo+1;i<hi;i++){int v=ids[i],j=i;while(j>lo&&bdk_less(v,ids[j-1],axis,x,y)){ids[j]=ids[j-1];j--;}ids[j]=v;}
    int mid=lo+(hi-lo)/2,at=(*used)++;nodes[at].id=ids[mid];nodes[at].left=bdk_build(ids,lo,mid,depth+1,x,y,nodes,used);nodes[at].right=bdk_build(ids,mid+1,hi,depth+1,x,y,nodes,used);
    int id=nodes[at].id;nodes[at].minx=nodes[at].maxx=x[id];nodes[at].miny=nodes[at].maxy=y[id];
    int children[2]={nodes[at].left,nodes[at].right};for(int k=0;k<2;k++)if(children[k]>=0){BdkNode c=nodes[children[k]];if(c.minx<nodes[at].minx)nodes[at].minx=c.minx;if(c.maxx>nodes[at].maxx)nodes[at].maxx=c.maxx;if(c.miny<nodes[at].miny)nodes[at].miny=c.miny;if(c.maxy>nodes[at].maxy)nodes[at].maxy=c.maxy;}return at;
}
static int64_t bdk_box_distance(const BdkNode *n,int64_t qx,int64_t qy){int64_t dx=qx<n->minx?n->minx-qx:qx>n->maxx?qx-n->maxx:0;int64_t dy=qy<n->miny?n->miny-qy:qy>n->maxy?qy-n->maxy:0;return dx*dx+dy*dy;}
static void bdk_query(int at,const BdkNode nodes[32],const int64_t x[32],const int64_t y[32],const uint8_t active[32],int64_t qx,int64_t qy,int *found,int *best_id,int64_t *best){
    if(at<0||(*found&&bdk_box_distance(&nodes[at],qx,qy)>*best))return;const BdkNode *n=&nodes[at];int id=n->id;if(active[id]){int64_t dx=x[id]-qx,dy=y[id]-qy,d=dx*dx+dy*dy;if(!*found||d<*best||(d==*best&&id<*best_id)){*found=1;*best=d;*best_id=id;}}
    int a=n->left,b=n->right;if(a>=0&&b>=0&&bdk_box_distance(&nodes[b],qx,qy)<bdk_box_distance(&nodes[a],qx,qy)){int t=a;a=b;b=t;}bdk_query(a,nodes,x,y,active,qx,qy,found,best_id,best);bdk_query(b,nodes,x,y,active,qx,qy,found,best_id,best);
}

static void bdk_insert(int levels[6][32],int sizes[6],int id){
    int carry[32],count=1;carry[0]=id;
    for(int level=0;level<6;level++){
        if(sizes[level]==0){for(int i=0;i<count;i++)levels[level][i]=carry[i];sizes[level]=count;return;}
        int next[32],next_count=0;for(int i=0;i<sizes[level];i++)next[next_count++]=levels[level][i];for(int i=0;i<count;i++)next[next_count++]=carry[i];sizes[level]=0;
        for(int i=0;i<next_count;i++)carry[i]=next[i];count=next_count;
    }
}

int64_t batch_dynamic_kd_tree(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<2||length>BDK_MAX_INPUT)return -1;int64_t init0=input[0];if(init0<0||init0>8||length<2+3*(size_t)init0)return -1;
    int64_t x[32]={0},y[32]={0};uint8_t ever[32]={0},active[32]={0};int levels[6][32]={{0}},sizes[6]={0};size_t pos=1;int inserted=0;
    for(int i=0;i<(int)init0;i++){
        int64_t id=input[pos++],px=input[pos++],py=input[pos++];if(id<0||id>=32||ever[id]||px<-1000||px>1000||py<-1000||py>1000)return -1;
        for(int j=0;j<32;j++)if(active[j]&&x[j]==px&&y[j]==py)return -1;x[id]=px;y[id]=py;ever[id]=active[id]=1;inserted++;bdk_insert(levels,sizes,(int)id);
    }
    if(pos>=length)return -1;int64_t batches0=input[pos++];if(batches0<1||batches0>8)return -1;int64_t answers[8];
    for(int batch=0;batch<(int)batches0;batch++){
        if(pos+2>length)return -1;int64_t kind=input[pos++],count0=input[pos++];if((kind!=0&&kind!=1)||count0<1||count0>8)return -1;int count=(int)count0;
        if(kind==0){if(inserted+count>32||pos+3*(size_t)count+2>length)return -1;
            for(int j=0;j<count;j++){int64_t id=input[pos++],px=input[pos++],py=input[pos++];if(id<0||id>=32||ever[id]||px<-1000||px>1000||py<-1000||py>1000)return -1;for(int t=0;t<32;t++)if(active[t]&&x[t]==px&&y[t]==py)return -1;for(int t=0;t<j;t++){size_t base=pos-3*(size_t)(j+1);if(input[base+3*t+1]==px&&input[base+3*t+2]==py)return -1;}x[id]=px;y[id]=py;ever[id]=active[id]=1;inserted++;bdk_insert(levels,sizes,(int)id);}
        }else{if(pos+(size_t)count+2>length)return -1;for(int j=0;j<count;j++){int64_t id=input[pos++];if(id<0||id>=32||!active[id])return -1;active[id]=0;}}
        int64_t qx=input[pos++],qy=input[pos++];if(qx<-1000||qx>1000||qy<-1000||qy>1000)return -1;int found=0;int64_t best=INT64_MAX;
        int best_id=0;for(int level=0;level<6;level++)if(sizes[level]){int ids[32];for(int j=0;j<sizes[level];j++)ids[j]=levels[level][j];BdkNode nodes[32];int used=0;int root=bdk_build(ids,0,sizes[level],0,x,y,nodes,&used);bdk_query(root,nodes,x,y,active,qx,qy,&found,&best_id,&best);}
        if(!found)return -1;answers[batch]=best;
    }
    if(pos!=length)return -1;size_t needed=8*(size_t)batches0;if(!output||capacity<needed)return -2;
    for(size_t i=0;i<needed;i++)output[i]=(uint8_t)((uint64_t)answers[i/8]>>(8*(i%8)));return (int64_t)needed;
}
