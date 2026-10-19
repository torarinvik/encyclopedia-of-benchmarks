module nbench_huffman_compression;
// BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
// Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE.
const usz MAX_TEXT=128;
const usz MAX_STREAM_BYTES=258;
const int EXCLUDED=32000;
struct HuffNode { uchar c; float freq; int parent; int left; int right; }
fn void put_u32(char* out,usz at,uint x){for(usz b=0;b<4;b++)out[at+b]=(char)(x>>(8*b));}

fn long nbench_huffman_compression(long* input,usz length,char* output,usz capacity) @export("nbench_huffman_compression") {
 if(input==null||length<2||length>MAX_TEXT+1)return -1;long raw_n=input[0];if(raw_n<1||raw_n>(long)MAX_TEXT||length!=(usz)(raw_n+1))return -1;usz n=(usz)raw_n,arraysize=n+1;
 uchar[MAX_TEXT+1] text=zeroed;bool[256] seen=zeroed;usz distinct=0;for(usz i=0;i<n;i++){long x=input[i+1];if(x<32||x>47)return -1;text[i]=(uchar)x;if(!seen[text[i]]){seen[text[i]]=true;distinct++;}}text[n]=0;if(!seen[0])distinct++;if(distinct<2)return -1;
 HuffNode[512] tree=zeroed;for(int i=0;i<256;i++){tree[i].c=(uchar)i;tree[i].freq=0.0f;tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1;}for(usz i=0;i<arraysize;i++)tree[text[i]].freq+=1.0f;for(int i=0;i<256;i++)if(tree[i].freq!=0.0f)tree[i].freq=tree[i].freq/(float)arraysize;for(int i=256;i<512;i++){tree[i].c=0;tree[i].freq=0.0f;tree[i].parent=EXCLUDED;tree[i].left=0;tree[i].right=0;}for(int i=0;i<512;i++){if(tree[i].freq==0.0f)tree[i].parent=EXCLUDED;else{tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1;}}
 int root=255;for(;;){float low1=2.0f,low2=2.0f;int idx1=-1,idx2=-1;for(int i=0;i<=root;i++)if(tree[i].parent<0&&tree[i].freq<low1){low1=tree[i].freq;idx1=i;}if(idx1<0)break;for(int i=0;i<=root;i++)if(tree[i].parent<0&&i!=idx1&&tree[i].freq<low2){low2=tree[i].freq;idx2=i;}if(idx2<0)break;root++;tree[idx1].parent=root;tree[idx2].parent=root;tree[root].freq=low1+low2;tree[root].left=idx1;tree[root].right=idx2;tree[root].parent=-2;}if(root<256||tree[root].left<0)return -1;
 uchar[MAX_STREAM_BYTES] stream=zeroed;usz bit_count=0;for(usz i=0;i<arraysize;i++){int[30] path;usz count=0;int node=(int)text[i];while(tree[node].parent!=-2){int par=tree[node].parent;if(par<0||par>=512||count>=30)return -1;path[count]=tree[par].left==node?0:1;count++;node=par;}while(count>0){count--;if(path[count]!=0)stream[bit_count/8]|=(uchar)(1<<(bit_count%8));bit_count++;}}
 uchar[MAX_TEXT+1] decoded=zeroed;usz bit=0,pos=0;while(bit<bit_count){int node=root;while(tree[node].left!=-1){int b=(stream[bit/8]>>(bit%8))&1;node=b==0?tree[node].left:tree[node].right;bit++;if(bit>bit_count)return -1;}if(pos>=arraysize)return -1;decoded[pos]=tree[node].c;pos++;}if(pos!=arraysize)return -1;for(usz i=0;i<arraysize;i++)if(decoded[i]!=text[i])return -1;
 usz stream_bytes=(bit_count+7)/8,total=4+stream_bytes;if(output==null||capacity<total)return -2;put_u32(output,0,(uint)bit_count);for(usz i=0;i<stream_bytes;i++)output[4+i]=(char)stream[i];return (long)total;
}
