module versabench_dbms_insert_entry;
const MAX_DEPTH=2;const MAX_CHILDREN=4;const MAX_LEAF=3;const MAX_WORDS=28;
fn bool valid_box(long* b){for(usz d=0;d<4;d++)if(b[d]<-8||b[d]>8||b[4+d]<-8||b[4+d]>8||b[d]>=b[4+d])return false;return true;}
fn void box_union(long* boxes,usz count,usz stride,long* out){for(usz d=0;d<4;d++){out[d]=boxes[d];out[4+d]=boxes[4+d];}for(usz i=1;i<count;i++)for(usz d=0;d<4;d++){long lo=boxes[i*stride+d];long hi=boxes[i*stride+4+d];if(lo<out[d])out[d]=lo;if(hi>out[4+d])out[4+d]=hi;}}
fn long volume(long* b){long v=1;for(usz d=0;d<4;d++)v*=b[4+d]-b[d];return v;}
fn bool same_box(long* a,long* b){for(usz i=0;i<8;i++)if(a[i]!=b[i])return false;return true;}
fn void write_i64(u8* out,usz word,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[word*8+b]=(u8)((bits>>(8*b))&255);}

fn long versabench_dbms_insert_entry(long* v,usz length,u8* output,usz output_capacity) @export("versabench_dbms_insert_entry"){
    if(v==null||length<11||length>105)return -1;long depthv=v[0];long new_id=v[1];if(depthv<0||depthv>MAX_DEPTH||new_id<0||new_id>=32)return -1;
    usz depth=(usz)depthv;long[8] incoming;for(usz i=0;i<8;i++)incoming[i]=v[2+i];if(!valid_box(&incoming[0]))return -1;
    long[MAX_DEPTH][MAX_CHILDREN][8] branches;usz[MAX_DEPTH] counts;usz pos=10;
    for(usz level=0;level<depth;level++){if(pos>=length)return -1;long cv=v[pos];pos++;if(cv<1||cv>MAX_CHILDREN||pos+(usz)cv*8>length)return -1;counts[level]=(usz)cv;for(usz i=0;i<counts[level];i++){for(usz j=0;j<8;j++)branches[level][i][j]=v[pos+j];pos+=8;if(!valid_box(&branches[level][i][0]))return -1;}}
    if(pos>=length)return -1;long lv=v[pos];pos++;if(lv<0||lv>MAX_LEAF||(depth>0&&lv==0)||pos+(usz)lv*9>length)return -1;usz leaf_count=(usz)lv;
    long[MAX_LEAF][9] leaf;bool[32] seen;for(usz i=0;i<32;i++)seen[i]=false;
    for(usz i=0;i<leaf_count;i++){for(usz j=0;j<9;j++)leaf[i][j]=v[pos+j];pos+=9;if(!valid_box(&leaf[i][0])||leaf[i][8]<0||leaf[i][8]>=32||seen[(usz)leaf[i][8]])return -1;seen[(usz)leaf[i][8]]=true;}
    if(pos!=length||seen[(usz)new_id])return -1;
    usz[MAX_DEPTH] choices;
    for(usz level=0;level<depth;level++){long best=65536;for(usz i=0;i<counts[level];i++){long[8] joined;for(usz d=0;d<4;d++){joined[d]=branches[level][i][d]<incoming[d]?branches[level][i][d]:incoming[d];joined[4+d]=branches[level][i][4+d]>incoming[4+d]?branches[level][i][4+d]:incoming[4+d];}long p=volume(&joined[0])-volume(&branches[level][i][0]);if(p<best){best=p;choices[level]=i;}}}
    if(depth>0){long[8] pre;box_union(&leaf[0][0],leaf_count,9,&pre[0]);usz rev=depth;while(rev>0){rev--;usz level=rev;if(!same_box(&branches[level][choices[level]][0],&pre[0]))return -1;box_union(&branches[level][0][0],counts[level],8,&pre[0]);}}
    long[MAX_LEAF+1][8] staged;for(usz i=0;i<leaf_count;i++)for(usz d=0;d<8;d++)staged[i][d]=leaf[i][d];for(usz d=0;d<8;d++)staged[leaf_count][d]=incoming[d];
    long[8] child;box_union(&staged[0][0],leaf_count+1,8,&child[0]);long[MAX_WORDS] result;usz outn=0;
    result[outn]=depth;outn++;result[outn]=new_id;outn++;for(usz i=0;i<depth;i++){result[outn]=choices[i];outn++;}for(usz d=0;d<8;d++){result[outn]=child[d];outn++;}
    usz rev2=depth;while(rev2>0){rev2--;usz level=rev2;for(usz d=0;d<8;d++)branches[level][choices[level]][d]=child[d];box_union(&branches[level][0][0],counts[level],8,&child[0]);for(usz d=0;d<8;d++){result[outn]=child[d];outn++;}}
    usz bytes=outn*8;if(output==null||output_capacity<bytes)return -2;for(usz i=0;i<outn;i++)write_i64(output,i,result[i]);return (long)bytes;
}
