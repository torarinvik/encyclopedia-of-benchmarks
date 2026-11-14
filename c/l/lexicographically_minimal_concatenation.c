/* Independent suffix-array/LCP draft; compilation and output are unverified. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct { int start, length; } lc_word;
typedef struct { const int *classes; int size, step; } lc_suffix_context;

static int suffix_before(int a, int b, const lc_suffix_context *ctx) {
    if (ctx->classes[a]!=ctx->classes[b]) return ctx->classes[a]<ctx->classes[b];
    int ac=a+ctx->step<ctx->size ? ctx->classes[a+ctx->step] : -1;
    int bc=b+ctx->step<ctx->size ? ctx->classes[b+ctx->step] : -1;
    return ac<bc;
}

static void sort_suffixes(int *values, int *scratch, int n, const lc_suffix_context *ctx) {
    for (int width=1; width<n; width*=2) {
        for (int start=0; start<n; start+=2*width) {
            int middle=start+width<n ? start+width : n;
            int end=start+2*width<n ? start+2*width : n;
            int a=start,b=middle,k=start;
            while (a<middle && b<end) {
                if (suffix_before(values[b],values[a],ctx)) scratch[k++]=values[b++];
                else scratch[k++]=values[a++];
            }
            while (a<middle) scratch[k++]=values[a++];
            while (b<end) scratch[k++]=values[b++];
        }
        for (int i=0; i<n; ++i) values[i]=scratch[i];
    }
}

typedef struct { const int *text, *rank, *logs, *table; int n; const lc_word *words; } lc_word_context;

static int common(const lc_word_context *ctx, int a, int b, int limit) {
    if (a==b) return limit;
    int lo=ctx->rank[a], hi=ctx->rank[b];
    if (lo>hi) { int temp=lo; lo=hi; hi=temp; }
    ++lo;
    int level=ctx->logs[hi-lo+1], width=1<<level;
    int x=ctx->table[level*ctx->n+lo], y=ctx->table[level*ctx->n+hi-width+1];
    int result=x<y ? x:y;
    return result<limit ? result:limit;
}

static int word_before(int a, int b, const lc_word_context *ctx) {
    lc_word left[2]={ctx->words[a],ctx->words[b]}, right[2]={ctx->words[b],ctx->words[a]};
    int li=0,ri=0,lp=0,rp=0;
    while (li<2 && ri<2) {
        int ln=left[li].length-lp, rn=right[ri].length-rp;
        int limit=ln<rn ? ln:rn;
        int same=common(ctx,left[li].start+lp,right[ri].start+rp,limit);
        if (same<limit) return ctx->text[left[li].start+lp+same]<ctx->text[right[ri].start+rp+same];
        lp+=same; rp+=same;
        if (lp==left[li].length) { ++li; lp=0; }
        if (rp==right[ri].length) { ++ri; rp=0; }
    }
    return a<b;
}

static void sort_words(int *values, int *scratch, int n, const lc_word_context *ctx) {
    for (int width=1; width<n; width*=2) {
        for (int start=0; start<n; start+=2*width) {
            int mid=start+width<n ? start+width:n;
            int end=start+2*width<n ? start+2*width:n;
            int a=start,b=mid,k=start;
            while (a<mid && b<end) {
                if (word_before(values[b],values[a],ctx)) scratch[k++]=values[b++];
                else scratch[k++]=values[a++];
            }
            while (a<mid) scratch[k++]=values[a++];
            while (b<end) scratch[k++]=values[b++];
        }
        for (int i=0; i<n; ++i) values[i]=scratch[i];
    }
}

int64_t lexicographically_minimal_concatenation(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (!input || length==0 || input[0]<0 || input[0]>16384) return -1;
    int count=(int)input[0];
    size_t at=1,total=0;
    for (int i=0; i<count; ++i) {
        if (at>=length || input[at]<1 || input[at]>65536) return -1;
        size_t size=(size_t)input[at++];
        if (size>65536-total || size>length-at) return -1;
        for (size_t j=0; j<size; ++j) if (input[at+j]<97 || input[at+j]>122) return -1;
        at+=size; total+=size;
    }
    if (at!=length) return -1;
    if (!output || capacity<total) return -2;
    if (count==0) return 0;
    int n=(int)total+count;
    int levels=1;
    while ((1<<levels)<=n) ++levels;
    lc_word *words=calloc((size_t)count,sizeof(*words));
    int *memory=calloc((size_t)(7+levels)*(size_t)n+1,sizeof(*memory));
    int *order=calloc((size_t)2*count,sizeof(*order));
    if (!words || !memory || !order) { free(words); free(memory); free(order); return -1; }
    int *text=memory, *sa=text+n, *scratch=sa+n, *classes=scratch+n;
    int *next=classes+n, *rank=next+n, *logs=rank+n, *table=logs+n+1;
    at=1; int used=0;
    for (int i=0; i<count; ++i) {
        int size=(int)input[at++];
        words[i]=(lc_word){used,size};
        for (int j=0; j<size; ++j) text[used++]=(int)input[at++];
        text[used++]=0;
    }
    for (int i=0; i<n; ++i) { sa[i]=i; classes[i]=text[i]; }
    for (int step=1; step<n; step*=2) {
        lc_suffix_context ctx={classes,n,step};
        sort_suffixes(sa,scratch,n,&ctx);
        next[sa[0]]=0;
        for (int i=1; i<n; ++i) next[sa[i]]=next[sa[i-1]]+suffix_before(sa[i-1],sa[i],&ctx);
        int *swap=classes; classes=next; next=swap;
        if (classes[sa[n-1]]==n-1) break;
    }
    for (int i=0; i<n; ++i) rank[sa[i]]=i;
    int shared=0;
    for (int i=0; i<n; ++i) {
        int r=rank[i];
        if (r==0) { shared=0; continue; }
        int j=sa[r-1];
        while (i+shared<n && j+shared<n && text[i+shared]==text[j+shared]) ++shared;
        table[r]=shared;
        if (shared) --shared;
    }
    for (int i=2; i<=n; ++i) logs[i]=logs[i/2]+1;
    for (int level=1; level<levels; ++level) {
        int width=1<<level, half=width/2;
        for (int i=0; i+width<=n; ++i) {
            int a=table[(level-1)*n+i], b=table[(level-1)*n+i+half];
            table[level*n+i]=a<b ? a:b;
        }
    }
    lc_word_context context={text,rank,logs,table,n,words};
    for (int i=0; i<count; ++i) order[i]=i;
    sort_words(order,order+count,count,&context);
    size_t written=0;
    for (int i=0; i<count; ++i) {
        lc_word word=words[order[i]];
        for (int j=0; j<word.length; ++j) output[written++]=(uint8_t)text[word.start+j];
    }
    free(order); free(memory); free(words);
    return (int64_t)written;
}
