module versabench_dbms_query;

const MAX_NODES = 7; const MAX_ENTRIES = 4; const MAX_RECORDS = 16;
struct DbmsEntry { long[4] lo; long[4] hi; long reference; }
struct DbmsNode { long level; usz count; DbmsEntry[4] entries; }

fn bool valid_box(long* lo,long* hi) {
    for(usz d=0;d<4;d++) if(lo[d]<-8||lo[d]>8||hi[d]<-8||hi[d]>8||lo[d]>=hi[d]) return false;
    return true;
}
fn bool intersects(DbmsEntry* e,long* lo,long* hi) {
    for(usz d=0;d<4;d++) if(lo[d]>e.hi[d]||e.lo[d]>hi[d]) return false;
    return true;
}
fn void write_i64(u8* output,usz word,long value) {
    ulong bits=(ulong)value;
    for(usz b=0;b<8;b++) output[word*8+b]=(u8)((bits>>(8*b))&255);
}

fn long versabench_dbms_query(long* v,usz length,u8* output,usz output_capacity) @export("versabench_dbms_query") {
    if(v==null||length<10||length>277)return -1;
    long nn=v[0];long rootv=v[1];if(nn<1||nn>MAX_NODES||rootv<0||rootv>=nn)return -1;
    usz n=(usz)nn;usz root=(usz)rootv;
    long[4] qlo;long[4] qhi;for(usz d=0;d<4;d++){qlo[d]=v[2+d];qhi[d]=v[6+d];}
    if(!valid_box(&qlo[0],&qhi[0]))return -1;
    DbmsNode[MAX_NODES] nodes;usz[MAX_NODES] parents;bool[32] seen;
    for(usz i=0;i<MAX_NODES;i++)parents[i]=0;for(usz i=0;i<32;i++)seen[i]=false;
    usz leaf_total=0;usz pos=10;
    for(usz ni=0;ni<n;ni++){
        if(pos+2>length)return -1;long level=v[pos];long countv=v[pos+1];pos+=2;
        if(level<0||level>2||countv<1||countv>MAX_ENTRIES||pos+(usz)countv*9>length)return -1;
        usz count=(usz)countv;nodes[ni].level=level;nodes[ni].count=count;
        for(usz ei=0;ei<count;ei++){
            DbmsEntry* e=&nodes[ni].entries[ei];for(usz d=0;d<4;d++)e.lo[d]=v[pos+d];pos+=4;for(usz d=0;d<4;d++)e.hi[d]=v[pos+d];pos+=4;e.reference=v[pos];pos+=1;
            if(!valid_box(&e.lo[0],&e.hi[0]))return -1;
            if(level==0){if(e.reference<0||e.reference>=32||seen[(usz)e.reference]||leaf_total>=MAX_RECORDS)return -1;seen[(usz)e.reference]=true;leaf_total++;}
            else{if(e.reference<0||e.reference>=nn)return -1;parents[(usz)e.reference]++;if(parents[(usz)e.reference]>1)return -1;}
        }
    }
    if(pos!=length||parents[root]!=0)return -1;
    for(usz ni=0;ni<n;ni++){
        if(ni!=root&&parents[ni]!=1)return -1;if(nodes[ni].level==0)continue;
        for(usz ei=0;ei<nodes[ni].count;ei++){
            DbmsEntry* branch=&nodes[ni].entries[ei];DbmsNode* child=&nodes[(usz)branch.reference];
            if(child.level!=nodes[ni].level-1)return -1;
            for(usz ce=0;ce<child.count;ce++)for(usz d=0;d<4;d++)if(branch.lo[d]>child.entries[ce].lo[d]||branch.hi[d]<child.entries[ce].hi[d])return -1;
        }
    }
    usz[MAX_NODES] stack;usz top=1;stack[0]=root;long[MAX_RECORDS] hits;usz hit_count=0;
    while(top>0){top--;usz ni=stack[top];DbmsNode* node=&nodes[ni];
        if(node.level==0){for(usz ei=0;ei<node.count;ei++){DbmsEntry* e=&node.entries[ei];if(intersects(e,&qlo[0],&qhi[0])){hits[hit_count]=e.reference;hit_count++;}}}
        else{usz rev=node.count;while(rev>0){rev--;DbmsEntry* e=&node.entries[rev];if(intersects(e,&qlo[0],&qhi[0])){stack[top]=(usz)e.reference;top++;}}}
    }
    usz bytes=hit_count*8;if(output==null||output_capacity<bytes)return -2;
    for(usz i=0;i<hit_count;i++)write_i64(output,i,hits[i]);return (long)bytes;
}
