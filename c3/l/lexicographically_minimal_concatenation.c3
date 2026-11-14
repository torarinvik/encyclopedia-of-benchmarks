// Independent suffix-array/LCP draft; compilation and output are unverified.
module lexicographically_minimal_concatenation;
extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

struct LmcCtx { long* text; long* rank; long* logs; long* table; long* starts; long* sizes; usz n; }

fn bool suffix_before(usz a, usz b, usz step, usz n, long* classes) {
    if (classes[a]!=classes[b]) return classes[a]<classes[b];
    long aa=a+step<n ? classes[a+step] : -1;
    long bb=b+step<n ? classes[b+step] : -1;
    return aa<bb;
}
fn void sort_suffixes(long* sa, long* scratch, usz n, usz step, long* classes) {
    for (usz width=1; width<n; width*=2) {
        usz start=0;
        while (start<n) {
            usz mid=start+width<n ? start+width : n;
            usz end=start+2*width<n ? start+2*width : n;
            usz a=start,b=mid,out=start;
            while (a<mid && b<end) {
                if (suffix_before((usz)sa[b],(usz)sa[a],step,n,classes)) scratch[out++]=sa[b++];
                else scratch[out++]=sa[a++];
            }
            while (a<mid) scratch[out++]=sa[a++];
            while (b<end) scratch[out++]=sa[b++];
            start=end;
        }
        for (usz i=0; i<n; i++) sa[i]=scratch[i];
    }
}
fn usz common(LmcCtx* ctx, usz a, usz b, usz limit) {
    if (a==b) return limit;
    usz low=(usz)ctx.rank[a], high=(usz)ctx.rank[b];
    if (low>high) { usz temp=low; low=high; high=temp; }
    low++;
    usz level=(usz)ctx.logs[high-low+1], span=1<<level;
    usz x=(usz)ctx.table[level*ctx.n+low], y=(usz)ctx.table[level*ctx.n+high-span+1];
    usz best=x<y ? x : y;
    return best<limit ? best : limit;
}
fn bool word_before(LmcCtx* ctx, usz a, usz b) {
    usz[2] left={a,b}, right={b,a};
    usz li=0,ri=0,lp=0,rp=0;
    while (li<2 && ri<2) {
        usz lw=left[li], rw=right[ri];
        usz ln=(usz)ctx.sizes[lw]-lp, rn=(usz)ctx.sizes[rw]-rp;
        usz limit=ln<rn ? ln : rn;
        usz x=(usz)ctx.starts[lw]+lp, y=(usz)ctx.starts[rw]+rp;
        usz same=common(ctx,x,y,limit);
        if (same<limit) return ctx.text[x+same]<ctx.text[y+same];
        lp+=same; rp+=same;
        if (lp==(usz)ctx.sizes[lw]) { li++; lp=0; }
        if (rp==(usz)ctx.sizes[rw]) { ri++; rp=0; }
    }
    return a<b;
}
fn void sort_words(long* order, long* scratch, usz count, LmcCtx* ctx) {
    for (usz width=1; width<count; width*=2) {
        usz start=0;
        while (start<count) {
            usz mid=start+width<count ? start+width : count;
            usz end=start+2*width<count ? start+2*width : count;
            usz a=start,b=mid,out=start;
            while (a<mid && b<end) {
                if (word_before(ctx,(usz)order[b],(usz)order[a])) scratch[out++]=order[b++];
                else scratch[out++]=order[a++];
            }
            while (a<mid) scratch[out++]=order[a++];
            while (b<end) scratch[out++]=order[b++];
            start=end;
        }
        for (usz i=0; i<count; i++) order[i]=scratch[i];
    }
}

fn long lexicographically_minimal_concatenation(long* input, usz length, char* output, usz capacity)
    @export("lexicographically_minimal_concatenation") {
    if (input==null || length==0 || input[0]<0 || input[0]>16384) return -1;
    usz count=(usz)input[0], offset=1, total=0;
    for (usz i=0; i<count; i++) {
        if (offset>=length || input[offset]<1 || input[offset]>65536) return -1;
        usz size=(usz)input[offset++];
        if (size>65536-total || size>length-offset) return -1;
        for (usz j=0; j<size; j++) if (input[offset+j]<97 || input[offset+j]>122) return -1;
        offset+=size; total+=size;
    }
    if (offset!=length) return -1;
    if (output==null || capacity<total) return -2;
    if (count==0) return 0;
    usz n=total+count, levels=1;
    while ((1<<levels)<=n) levels++;
    usz workspace_size=(7+levels)*n+1+4*count;
    long* memory=(long*)calloc(workspace_size,sizeof(long));
    if (memory==null) return -1;
    long* text=memory; long* sa=text+n; long* scratch=sa+n; long* classes=scratch+n;
    long* next=classes+n; long* rank=next+n; long* logs=rank+n; long* table=logs+n+1;
    long* starts=table+levels*n; long* sizes=starts+count;
    long* order=sizes+count; long* word_scratch=order+count;
    offset=1; usz used=0;
    for (usz i=0; i<count; i++) {
        usz size=(usz)input[offset++]; starts[i]=(long)used; sizes[i]=(long)size;
        for (usz j=0; j<size; j++) text[used++]=input[offset+j];
        offset+=size; text[used++]=0;
    }
    for (usz i=0; i<n; i++) { sa[i]=(long)i; classes[i]=text[i]; }
    for (usz step=1; step<n; step*=2) {
        sort_suffixes(sa,scratch,n,step,classes);
        next[(usz)sa[0]]=0;
        for (usz i=1; i<n; i++) {
            usz a=(usz)sa[i-1], b=(usz)sa[i];
            next[b]=next[a]+(suffix_before(a,b,step,n,classes) ? 1 : 0);
        }
        long* temp=classes; classes=next; next=temp;
        if (classes[(usz)sa[n-1]]==(long)(n-1)) break;
    }
    for (usz i=0; i<n; i++) rank[(usz)sa[i]]=(long)i;
    usz shared=0;
    for (usz i=0; i<n; i++) {
        usz r=(usz)rank[i];
        if (r==0) { shared=0; continue; }
        usz j=(usz)sa[r-1];
        while (i+shared<n && j+shared<n && text[i+shared]==text[j+shared]) shared++;
        table[r]=(long)shared;
        if (shared>0) shared--;
    }
    for (usz i=2; i<=n; i++) logs[i]=logs[i/2]+1;
    for (usz level=1; level<levels; level++) {
        usz width=1<<level, half=width/2;
        for (usz i=0; i+width<=n; i++) {
            long a=table[(level-1)*n+i], b=table[(level-1)*n+i+half];
            table[level*n+i]=a<b ? a : b;
        }
    }
    for (usz i=0; i<count; i++) order[i]=(long)i;
    LmcCtx ctx={text,rank,logs,table,starts,sizes,n};
    sort_words(order,word_scratch,count,&ctx);
    usz written=0;
    for (usz i=0; i<count; i++) {
        usz word=(usz)order[i];
        for (usz j=0; j<(usz)sizes[word]; j++) output[written++]=(char)text[(usz)starts[word]+j];
    }
    free(memory);
    return (long)written;
}
