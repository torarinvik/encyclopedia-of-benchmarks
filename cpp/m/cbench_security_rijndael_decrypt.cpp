#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t cbench_security_rijndael_decrypt(const std::int64_t*,std::size_t,std::uint8_t*,std::size_t);
namespace {
using B=std::uint8_t; constexpr std::size_t N=16;
B mul(B a,B b){B r=0;while(b){if(b&1)r^=a;a=B((a<<1)^((a&128)?0x1b:0));b>>=1;}return r;}
B powg(B a,unsigned n){B r=1;while(n){if(n&1)r=mul(r,a);a=mul(a,a);n>>=1;}return r;}
B rot(B a,unsigned n){return B((a<<n)|(a>>(8-n)));}
void decrypt(const B*key,const B*in,B*out){std::array<B,256>s{},iv{};std::array<B,240>rk{};constexpr B rc[7]={1,2,4,8,16,32,64};for(unsigned x=0;x<256;x++){B q=x?powg(B(x),254):0;s[x]=B(q^rot(q,1)^rot(q,2)^rot(q,3)^rot(q,4)^0x63);}for(unsigned x=0;x<256;x++)iv[s[x]]=B(x);for(unsigned i=0;i<32;i++)rk[i]=key[i];for(std::size_t w=32;w<240;){unsigned wi=unsigned(w/4);B t[4]={rk[w-4],rk[w-3],rk[w-2],rk[w-1]};if(wi%8==0){B a=t[0];t[0]=s[t[1]]^rc[wi/8-1];t[1]=s[t[2]];t[2]=s[t[3]];t[3]=s[a];}else if(wi%8==4)for(B&v:t)v=s[v];for(unsigned j=0;j<4;j++,w++)rk[w]=rk[w-32]^t[j];}
 std::array<B,16>st{};for(unsigned i=0;i<16;i++)st[i]=in[i]^rk[224+i];for(int round=13;round>0;round--){auto p=st;for(unsigned c=0;c<4;c++)for(unsigned r=0;r<4;r++)st[r+4*c]=iv[p[r+4*((c+4-r)%4)]];for(unsigned i=0;i<16;i++)st[i]^=rk[round*16+i];for(unsigned c=0;c<4;c++){unsigned o=4*c;B a=st[o],b=st[o+1],d=st[o+2],e=st[o+3];st[o]=mul(a,14)^mul(b,11)^mul(d,13)^mul(e,9);st[o+1]=mul(a,9)^mul(b,14)^mul(d,11)^mul(e,13);st[o+2]=mul(a,13)^mul(b,9)^mul(d,14)^mul(e,11);st[o+3]=mul(a,11)^mul(b,13)^mul(d,9)^mul(e,14);}}
 auto p=st;for(unsigned c=0;c<4;c++)for(unsigned r=0;r<4;r++)st[r+4*c]=iv[p[r+4*((c+4-r)%4)]];for(unsigned i=0;i<16;i++)out[i]=st[i]^rk[i];}
}
extern "C" std::int64_t cbench_security_rijndael_decrypt(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){if(!v||n!=48)return -1;for(std::size_t i=0;i<48;i++)if(v[i]<0||v[i]>255)return -1;if(!out||cap<16)return -2;B key[32],in[16];for(unsigned i=0;i<32;i++)key[i]=B(v[i]);for(unsigned i=0;i<16;i++)in[i]=B(v[32+i]);decrypt(key,in,out);return 16;}
