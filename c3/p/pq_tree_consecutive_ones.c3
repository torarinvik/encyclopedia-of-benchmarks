module pq_tree_consecutive_ones;

const int MAX_N = 20, MAX_M = 32, MAX_INPUT = 35, MAX_NODES = 128, MAX_OUTPUT = 648;
const u8 LEAF = 0, P_NODE = 1, Q_NODE = 2, WHITE = 0, BLACK = 1, MIXED = 2;
struct PqNode { u8 kind; u8 count; u8 arg; u8[MAX_N] child; }
struct PqTree { PqNode[MAX_NODES] nodes; u8[MAX_NODES] color; u8[MAX_NODES] free_id; int next_id; int free_count; int root; }

fn int pq_new(PqTree* t, int kind) {
    int id;
    if (t->free_count > 0) { t->free_count--; id = t->free_id[t->free_count]; }
    else { if (t->next_id >= MAX_NODES) return -1; id = t->next_id; t->next_id++; }
    t->nodes[id] = {};
    t->nodes[id].kind = (u8)kind;
    return id;
}
fn void pq_delete(PqTree* t, int id) { t->nodes[id].count = 0; t->free_id[t->free_count] = (u8)id; t->free_count++; }
fn void pq_push(PqTree* t, int id, int child) { int k = t->nodes[id].count; t->nodes[id].child[k] = (u8)child; t->nodes[id].count++; }

fn int pq_paint(PqTree* t, int id, ulong mask) {
    if (t->nodes[id].kind == LEAF) {
        t->color[id] = ((mask >> t->nodes[id].arg) & 1ul) != 0 ? BLACK : WHITE;
        return t->color[id];
    }
    bool saw_white = false, saw_black = false;
    for (int i = 0; i < t->nodes[id].count; i++) {
        int shade = pq_paint(t, t->nodes[id].child[i], mask);
        if (shade != BLACK) saw_white = true;
        if (shade != WHITE) saw_black = true;
    }
    t->color[id] = saw_white && saw_black ? MIXED : saw_black ? BLACK : WHITE;
    return t->color[id];
}
fn bool pq_pattern(PqTree* t, u8* children, int count) {
    int pivot = -1, mixed = 0;
    for (int i = 0; i < count; i++) if (t->color[children[i]] == MIXED) { pivot = i; mixed++; if (mixed > 1) return false; }
    if (mixed == 0) for (int i = 0; i < count; i++) if (t->color[children[i]] == BLACK) { pivot = i; break; }
    if (pivot < 0) return false;
    for (int i = 0; i < pivot; i++) if (t->color[children[i]] != WHITE) return false;
    for (int i = pivot + 1; i < count; i++) if (t->color[children[i]] != BLACK) return false;
    return true;
}

fn bool pq_split(PqTree* t, int id, u8* out, int* out_count) {
    if (t->color[id] != MIXED) { out[0] = (u8)id; out_count[0] = 1; return true; }
    u8[MAX_N] old = {}, white = {}, black = {}, mixed = {};
    int count = t->nodes[id].count, nw = 0, nb = 0, nm = 0, used = 0;
    for (int i = 0; i < count; i++) {
        old[i] = t->nodes[id].child[i];
        int shade = t->color[old[i]];
        if (shade == WHITE) { white[nw] = old[i]; nw++; }
        else if (shade == BLACK) { black[nb] = old[i]; nb++; }
        else { mixed[nm] = old[i]; nm++; }
    }
    if (t->nodes[id].kind == Q_NODE) {
        if (!pq_pattern(t, &old[0], count)) {
            for (int l = 0, r = count - 1; l < r; l++, r--) { u8 x = old[l]; old[l] = old[r]; old[r] = x; }
            if (!pq_pattern(t, &old[0], count)) return false;
        }
        for (int i = 0; i < count; i++) {
            if (t->color[old[i]] == MIXED) {
                u8[MAX_N] part = {}; int part_count = 0;
                if (!pq_split(t, old[i], &part[0], &part_count)) return false;
                for (int j = 0; j < part_count; j++) { out[used] = part[j]; used++; }
            } else { out[used] = old[i]; used++; }
        }
    } else {
        if (nm > 1) return false;
        if (nw > 0) { int group = pq_new(t, P_NODE); if (group < 0) return false; for (int i=0;i<nw;i++) pq_push(t,group,white[i]); out[used]=(u8)group; used++; }
        if (nm > 0) { u8[MAX_N] part = {}; int part_count=0; if (!pq_split(t,mixed[0],&part[0],&part_count)) return false; for(int i=0;i<part_count;i++){out[used]=part[i];used++;} }
        if (nb > 0) { int group = pq_new(t,P_NODE); if(group<0)return false; for(int i=0;i<nb;i++)pq_push(t,group,black[i]); out[used]=(u8)group; used++; }
    }
    pq_delete(t,id); out_count[0]=used; return true;
}

fn bool pq_work(PqTree* t, int id) {
    if (t->color[id] != MIXED) return true;
    u8[MAX_N] old = {}, white = {}, black = {}, mixed = {};
    int count=t->nodes[id].count,nw=0,nb=0,nm=0;
    for(int i=0;i<count;i++){old[i]=t->nodes[id].child[i];int shade=t->color[old[i]];if(shade==WHITE){white[nw]=old[i];nw++;}else if(shade==BLACK){black[nb]=old[i];nb++;}else{mixed[nm]=old[i];nm++;}}
    if(t->nodes[id].kind==P_NODE){
        if(nb==0&&nm==1)return pq_work(t,mixed[0]);
        if(nm>2)return false;
        int q=pq_new(t,Q_NODE);if(q<0)return false;
        for(int i=0;i<nw;i++)t->nodes[id].child[i]=white[i];
        t->nodes[id].child[nw]=(u8)q;t->nodes[id].count=(u8)(nw+1);
        if(nm>0){u8[MAX_N] part={};int pc=0;if(!pq_split(t,mixed[0],&part[0],&pc))return false;for(int i=0;i<pc;i++)pq_push(t,q,part[i]);}
        if(nb>0){int group=pq_new(t,P_NODE);if(group<0)return false;for(int i=0;i<nb;i++)pq_push(t,group,black[i]);pq_push(t,q,group);}
        if(nm==2){u8[MAX_N] part={};int pc=0;if(!pq_split(t,mixed[1],&part[0],&pc))return false;for(int i=pc-1;i>=0;i--)pq_push(t,q,part[i]);}
        return true;
    }
    int left=-1,right=-1;for(int i=0;i<count;i++)if(t->color[old[i]]!=WHITE){if(left<0)left=i;right=i;}
    if(left<0)return false;for(int i=left+1;i<right;i++)if(t->color[old[i]]!=BLACK)return false;
    if(left==right&&t->color[old[left]]==MIXED)return pq_work(t,old[left]);
    u8[MAX_N] result={},part={};int used=0,pc=0;for(int i=0;i<left;i++){result[used]=old[i];used++;}
    if(!pq_split(t,old[left],&part[0],&pc))return false;for(int i=0;i<pc;i++){result[used]=part[i];used++;}
    for(int i=left+1;i<right;i++){result[used]=old[i];used++;}
    if(right!=left){pc=0;if(!pq_split(t,old[right],&part[0],&pc))return false;for(int i=pc-1;i>=0;i--){result[used]=part[i];used++;}}
    for(int i=right+1;i<count;i++){result[used]=old[i];used++;}
    t->nodes[id].count=(u8)used;for(int i=0;i<used;i++)t->nodes[id].child[i]=result[i];return true;
}
fn int pq_normalize(PqTree* t,int id){if(t->nodes[id].kind==LEAF)return id;int count=t->nodes[id].count;for(int i=0;i<count;i++)t->nodes[id].child[i]=(u8)pq_normalize(t,t->nodes[id].child[i]);if(t->nodes[id].count==1){int child=t->nodes[id].child[0];pq_delete(t,id);return child;}if(t->nodes[id].kind==Q_NODE&&t->nodes[id].count==2)t->nodes[id].kind=P_NODE;return id;}
fn int pq_compare(PqTree* t,int a,int b){u8 ka=t->nodes[a].kind,kb=t->nodes[b].kind;int aa=ka==LEAF?t->nodes[a].arg:t->nodes[a].count,ab=kb==LEAF?t->nodes[b].arg:t->nodes[b].count;if(ka!=kb)return ka<kb?-1:1;if(aa!=ab)return aa<ab?-1:1;if(ka==LEAF)return 0;for(int i=0;i<t->nodes[a].count;i++){int c=pq_compare(t,t->nodes[a].child[i],t->nodes[b].child[i]);if(c!=0)return c;}return 0;}
fn void pq_canonical(PqTree* t,int id){if(t->nodes[id].kind==LEAF)return;int count=t->nodes[id].count;for(int i=0;i<count;i++)pq_canonical(t,t->nodes[id].child[i]);if(t->nodes[id].kind==P_NODE){for(int i=1;i<count;i++){u8 item=t->nodes[id].child[i];int j=i;while(j>0&&pq_compare(t,item,t->nodes[id].child[j-1])<0){t->nodes[id].child[j]=t->nodes[id].child[j-1];j--;}t->nodes[id].child[j]=item;}}else{int cmp=0;for(int i=0;i<count;i++){cmp=pq_compare(t,t->nodes[id].child[i],t->nodes[id].child[count-1-i]);if(cmp!=0)break;}if(cmp>0)for(int l=0,r=count-1;l<r;l++,r--){u8 x=t->nodes[id].child[l];t->nodes[id].child[l]=t->nodes[id].child[r];t->nodes[id].child[r]=x;}}}
fn long pq_frontiers(PqTree* t,int id){if(t->nodes[id].kind==LEAF)return 1;long result=1;for(int i=0;i<t->nodes[id].count;i++)result*=pq_frontiers(t,t->nodes[id].child[i]);if(t->nodes[id].kind==P_NODE)for(int i=2;i<=t->nodes[id].count;i++)result*=i;else result*=2;return result;}
fn int pq_count(PqTree* t,int id){int result=1;if(t->nodes[id].kind!=LEAF)for(int i=0;i<t->nodes[id].count;i++)result+=pq_count(t,t->nodes[id].child[i]);return result;}
fn void pq_serialize(PqTree* t,int id,long* words,int* used){words[*used]=t->nodes[id].kind;(*used)++;words[*used]=t->nodes[id].kind==LEAF?t->nodes[id].arg:t->nodes[id].count;(*used)++;if(t->nodes[id].kind!=LEAF)for(int i=0;i<t->nodes[id].count;i++)pq_serialize(t,t->nodes[id].child[i],words,used);}
fn void pq_store(u8* out,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[offset+b]=(u8)(bits&255);bits>>=8;}}

fn long pq_tree_consecutive_ones(long* input,usz length,u8* output,usz capacity) @export("pq_tree_consecutive_ones") {
    if(input==null||length<2||length>MAX_INPUT)return -1;long nraw=input[0],mraw=input[1];if(nraw<2||nraw>MAX_N||mraw<0||mraw>MAX_M||length!=2+(usz)mraw)return -1;
    int n=(int)nraw,m=(int)mraw;ulong valid=(1ul<<n)-1;for(int r=0;r<m;r++)if(input[2+r]<0||((ulong)input[2+r]&~valid)!=0)return -1;
    PqTree t={};t.next_id=n+1;t.root=n;for(int i=0;i<n;i++){t.nodes[i].kind=LEAF;t.nodes[i].arg=(u8)i;}t.nodes[n].kind=P_NODE;t.nodes[n].count=(u8)n;for(int i=0;i<n;i++)t.nodes[n].child[i]=(u8)i;
    for(int r=0;r<m;r++){pq_paint(&t,t.root,(ulong)input[2+r]);if(!pq_work(&t,t.root)){u8[24] staged={};long[3] zeros={0,0,0};for(int i=0;i<3;i++)pq_store(&staged[0],(usz)i*8,zeros[i]);if(output==null||capacity<24)return -2;for(usz i=0;i<24;i++)output[i]=staged[i];return 24;}t.root=pq_normalize(&t,t.root);}
    pq_canonical(&t,t.root);long[81] words={};int used=0;words[used++]=1;words[used++]=pq_frontiers(&t,t.root);words[used++]=pq_count(&t,t.root);pq_serialize(&t,t.root,&words[0],&used);u8[MAX_OUTPUT] staged={};for(int i=0;i<used;i++)pq_store(&staged[0],(usz)i*8,words[i]);usz bytes=(usz)used*8;if(output==null||capacity<bytes)return -2;for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
