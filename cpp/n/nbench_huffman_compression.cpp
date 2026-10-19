/* BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
 * Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE. */
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t MAX_TEXT=128, MAX_STREAM_BYTES=258;
constexpr int EXCLUDED=32000;
struct HuffNode { std::uint8_t c; float freq; int parent,left,right; };
void put_u32(std::uint8_t*out,std::uint32_t x){for(std::size_t i=0;i<4;++i)out[i]=static_cast<std::uint8_t>(x>>(8*i));}
}
extern "C" std::int64_t nbench_huffman_compression(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(!input||length<2||length>MAX_TEXT+1)return -1;const auto raw_n=input[0];if(raw_n<1||raw_n>static_cast<std::int64_t>(MAX_TEXT)||length!=static_cast<std::size_t>(raw_n)+1)return -1;
 const auto n=static_cast<std::size_t>(raw_n),arraysize=n+1;std::uint8_t text[MAX_TEXT+1]{};bool seen[256]{};std::size_t distinct=0;
 for(std::size_t i=0;i<n;++i){if(input[i+1]<32||input[i+1]>47)return -1;text[i]=static_cast<std::uint8_t>(input[i+1]);if(!seen[text[i]]){seen[text[i]]=true;++distinct;}}text[n]=0;if(!seen[0])++distinct;if(distinct<2)return -1;
 HuffNode tree[512]{};for(int i=0;i<256;++i){tree[i].freq=0.0f;tree[i].c=static_cast<std::uint8_t>(i);tree[i].parent=tree[i].left=tree[i].right=-1;}for(std::size_t i=0;i<arraysize;++i)tree[text[i]].freq+=1.0f;
 for(int i=0;i<256;++i)if(tree[i].freq!=0.0f)tree[i].freq=static_cast<float>(tree[i].freq/static_cast<float>(arraysize));for(int i=256;i<512;++i){tree[i].c=0;tree[i].freq=0.0f;tree[i].parent=EXCLUDED;tree[i].left=tree[i].right=0;}for(int i=0;i<512;++i){if(tree[i].freq==0.0f)tree[i].parent=EXCLUDED;else tree[i].parent=tree[i].left=tree[i].right=-1;}
 int root=255;for(;;){float low1=2.0f,low2=2.0f;int idx1=-1,idx2=-1;for(int i=0;i<=root;++i)if(tree[i].parent<0&&tree[i].freq<low1){low1=tree[i].freq;idx1=i;}if(idx1<0)break;for(int i=0;i<=root;++i)if(tree[i].parent<0&&i!=idx1&&tree[i].freq<low2){low2=tree[i].freq;idx2=i;}if(idx2<0)break;++root;tree[idx1].parent=root;tree[idx2].parent=root;tree[root].freq=low1+low2;tree[root].left=idx1;tree[root].right=idx2;tree[root].parent=-2;}if(root<256||tree[root].left<0)return -1;
 std::uint8_t stream[MAX_STREAM_BYTES]{};std::size_t bit_count=0;for(std::size_t i=0;i<arraysize;++i){int path[30],count=0,node=text[i];while(tree[node].parent!=-2){int p=tree[node].parent;if(p<0||p>=512||count>=30)return -1;path[count++]=tree[p].left==node?0:1;node=p;}while(count>0){if(path[--count])stream[bit_count>>3]|=static_cast<std::uint8_t>(1u<<(bit_count&7));++bit_count;}}
 std::uint8_t decoded[MAX_TEXT+1]{};std::size_t bit=0,pos=0;while(bit<bit_count){int node=root;while(tree[node].left!=-1){int b=(stream[bit>>3]>>(bit&7))&1;node=b?tree[node].right:tree[node].left;++bit;if(bit>bit_count)return -1;}if(pos>=arraysize)return -1;decoded[pos++]=tree[node].c;}if(pos!=arraysize)return -1;for(std::size_t i=0;i<arraysize;++i)if(decoded[i]!=text[i])return -1;
 const auto stream_bytes=(bit_count+7)/8,total=4+stream_bytes;if(!output||capacity<total)return -2;put_u32(output,static_cast<std::uint32_t>(bit_count));for(std::size_t i=0;i<stream_bytes;++i)output[4+i]=stream[i];return static_cast<std::int64_t>(total);
}
