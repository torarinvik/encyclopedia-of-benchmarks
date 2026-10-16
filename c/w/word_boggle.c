#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_CELLS 36
#define MAX_WORDS 32
#define MAX_WORD_LENGTH 15
#define MAX_NODES (1 + MAX_WORDS * MAX_WORD_LENGTH)

typedef struct { int child[52]; int word; } TrieNode;
static TrieNode trie[MAX_NODES];
static int node_count, rows, cols, cells;
static const int64_t *input_values;
static uint8_t visited[MAX_CELLS], found[MAX_WORDS];
static int word_starts[MAX_WORDS], word_lengths[MAX_WORDS];

static int letter_index(int64_t c) {
    if (c >= 'A' && c <= 'Z') return (int)(c - 'A');
    if (c >= 'a' && c <= 'z') return (int)(c - 'a' + 26);
    return -1;
}
static int cmp_words(int a, int b) {
    size_t ia=(size_t)word_starts[a], ib=(size_t)word_starts[b];
    size_t na=(size_t)word_lengths[a], nb=(size_t)word_lengths[b];
    size_t n=na<nb?na:nb;
    for (size_t i=0;i<n;i++) if(input_values[ia+1+i]!=input_values[ib+1+i]) return input_values[ia+1+i]<input_values[ib+1+i]?-1:1;
    return na<nb?-1:na>nb?1:0;
}
static void visit(int pos, int node) {
    if (visited[pos]) return;
    int k=letter_index(input_values[2+pos]);
    if(k<0) return;
    int next=trie[node].child[k];
    if(next<0) return;
    visited[pos]=1;
    if(trie[next].word>=0) found[trie[next].word]=1;
    int r=pos/cols,c=pos%cols;
    for(int dr=-1;dr<=1;dr++) for(int dc=-1;dc<=1;dc++) if(dr||dc){int nr=r+dr,nc=c+dc;if(nr>=0&&nr<rows&&nc>=0&&nc<cols)visit(nr*cols+nc,next);}
    visited[pos]=0;
}

int64_t word_boggle(const int64_t *v, size_t length, uint8_t *out, size_t cap) {
    if(!v||length<3||length>2+MAX_CELLS+1+MAX_WORDS*(MAX_WORD_LENGTH+1)) return -1;
    if(v[0]<1||v[0]>6||v[1]<1||v[1]>6)return -1;
    rows=(int)v[0];cols=(int)v[1];cells=rows*cols;
    size_t p=2+(size_t)cells;if(p>=length)return -1;
    if(v[p]<0||v[p]>MAX_WORDS)return -1;int count=(int)v[p++];
    for(int i=0;i<cells;i++)if(letter_index(v[2+i])<0)return -1;
    for(int i=0;i<count;i++){if(p>=length||v[p]<1||v[p]>MAX_WORD_LENGTH)return -1;int n=(int)v[p];if(p+1+(size_t)n>length)return -1;word_starts[i]=(int)p;word_lengths[i]=n;for(int j=0;j<n;j++)if(letter_index(v[p+1+j])<0)return -1;p+=(size_t)n+1;}
    if(p!=length)return -1;
    input_values=v;node_count=1;
    for(int n=0;n<node_count;n++){trie[n].word=-1;for(int k=0;k<52;k++)trie[n].child[k]=-1;}
    for(int i=0;i<count;i++){int node=0;size_t at=(size_t)word_starts[i];for(int j=0;j<word_lengths[i];j++){int k=letter_index(v[at+1+(size_t)j]);int child=trie[node].child[k];if(child<0){child=node_count++;trie[child].word=-1;for(int z=0;z<52;z++)trie[child].child[z]=-1;trie[node].child[k]=child;}node=child;}trie[node].word=i;}
    memset(visited,0,sizeof(visited));memset(found,0,sizeof(found));
    for(int i=0;i<cells;i++)visit(i,0);
    int order[MAX_WORDS];for(int i=0;i<count;i++)order[i]=i;
    for(int i=1;i<count;i++){int x=order[i],j=i;while(j>0&&cmp_words(order[j-1],x)>0){order[j]=order[j-1];j--;}order[j]=x;}
    size_t need=0;int last=-1;for(int j=0;j<count;j++){int i=order[j];if(found[i]&&(last<0||cmp_words(last,i)!=0)){need+=(size_t)word_lengths[i]+1;last=i;}}
    if(need>cap)return -2;if(need&&!out)return -1;
    size_t q=0;last=-1;for(int j=0;j<count;j++){int i=order[j];if(found[i]&&(last<0||cmp_words(last,i)!=0)){size_t at=(size_t)word_starts[i];for(int k=0;k<word_lengths[i];k++)out[q++]=(uint8_t)v[at+1+(size_t)k];out[q++]=0;last=i;}}
    return (int64_t)need;
}
