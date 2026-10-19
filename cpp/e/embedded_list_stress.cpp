/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
 * Apache-2.0 licensed upstream kernel, bounded variant; modifications made. */
#include <cstddef>
#include <cstdint>
#include <utility>
namespace {
constexpr int MAX_ITEMS=32;
struct Node{std::uint16_t data;std::int32_t idx;int next;};
std::uint16_t crc_byte(std::uint8_t v,std::uint16_t crc){for(int b=0;b<8;++b){auto mix=std::uint16_t((v&1u)^(crc&1u));v>>=1;if(mix)crc^=0x4002u;crc>>=1;if(mix)crc|=0x8000u;else crc&=0x7fffu;}return crc;}
std::uint16_t crc16(std::uint16_t v,std::uint16_t crc){return crc_byte(std::uint8_t(v>>8),crc_byte(std::uint8_t(v),crc));}
int compare(Node&a,Node&b,bool complex,std::uint16_t seed){if(complex){if(!(a.data&0x80u))a.data=std::uint16_t((a.data&0xff00u)|0x80u|((a.data^(a.data>>8)^seed)&0x7fu));if(!(b.data&0x80u))b.data=std::uint16_t((b.data&0xff00u)|0x80u|((b.data^(b.data>>8)^seed)&0x7fu));return int(a.data&127)-int(b.data&127);}a.data=std::uint16_t((a.data&0xff00u)|((a.data>>8)&255u));b.data=std::uint16_t((b.data&0xff00u)|((b.data>>8)&255u));return a.idx-b.idx;}
int sort_list(Node*a,int head,bool complex,std::uint16_t seed){int width=1;for(;;){int p=head,new_head=-1,tail=-1,merges=0;while(p>=0){++merges;int q=p,ps=0;for(int i=0;i<width;++i){++ps;q=a[q].next;if(q<0)break;}int qs=width;while(ps>0||(qs>0&&q>=0)){int e;if(ps==0){e=q;q=a[q].next;--qs;}else if(qs==0||q<0){e=p;p=a[p].next;--ps;}else if(compare(a[p],a[q],complex,seed)<=0){e=p;p=a[p].next;--ps;}else{e=q;q=a[q].next;--qs;}if(tail>=0)a[tail].next=e;else new_head=e;tail=e;}p=q;}a[tail].next=-1;head=new_head;if(merges<=1)return head;width*=2;}}
int find_node(Node*a,int head,int idx,int data){for(int p=head;p>=0;p=a[p].next)if(idx>=0?a[p].idx==idx:(a[p].data&255u)==std::uint16_t(data))return p;return -1;}
void reverse(Node*a,int&head){int prev=-1,cur=head;while(cur>=0){int next=a[cur].next;a[cur].next=prev;prev=cur;cur=next;}head=prev;}
}
extern "C" std::int64_t embedded_list_stress(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len!=4)return -1;auto rn=in[0],seed=in[1],find_n=in[2],finder_idx=in[3];if(rn<4||rn>MAX_ITEMS||seed<1||seed>255||find_n<0||find_n>32||!(finder_idx==-1||finder_idx==1))return -1;
 int n=int(rn),head=0,tail=n+1;Node a[MAX_ITEMS+2]{};a[0]={0x8080u,0,1};a[tail]={0xffffu,0x7fff,-1};for(int i=0;i<n;++i){auto pat=std::uint16_t((seed^i)&15),dat=std::uint16_t((pat<<3)|(i&7));a[i+1]={std::uint16_t((dat<<8)|dat),0,i+2};}a[n].next=tail;
 int i=1;for(int p=a[head].next;p!=tail;p=a[p].next){if(i<n/5)a[p].idx=i++;else{auto pat=std::uint16_t(i++^seed);a[p].idx=std::int32_t(((i&7)<<8)|pat)&0x3fff;}}head=sort_list(a,head,false,std::uint16_t(seed));
 int info_idx=int(finder_idx),info_data=0;std::uint16_t result=0;unsigned found=0,missed=0;for(int k=0;k<int(find_n);++k){info_data=k&255;int got=find_node(a,head,info_idx,info_data);reverse(a,head);if(got<0){++missed;int first=a[head].next;if(first>=0)result=std::uint16_t(result+((a[first].data>>8)&1));}else{++found;if(a[got].data&1u)result=std::uint16_t(result+((a[got].data>>9)&1));int next=a[got].next;if(next>=0){a[got].next=a[next].next;a[next].next=a[head].next;a[head].next=next;}}if(info_idx>=0)++info_idx;}result=std::uint16_t(result+found*4-missed);
 if(finder_idx>0)head=sort_list(a,head,true,std::uint16_t(seed));int at=a[head].next;if(at>=0){int rem=a[at].next;std::swap(a[at].data,a[rem].data);std::swap(a[at].idx,a[rem].idx);a[at].next=a[rem].next;a[rem].next=-1;int f=find_node(a,head,info_idx,info_data);if(f<0)f=a[head].next;while(f>=0){result=crc16(a[head].data,result);f=a[f].next;}std::swap(a[rem].data,a[at].data);std::swap(a[rem].idx,a[at].idx);a[rem].next=a[at].next;a[at].next=rem;}
 head=sort_list(a,head,false,std::uint16_t(seed));for(int f=a[head].next;f>=0;f=a[f].next)result=crc16(a[head].data,result);if(!out||cap<2)return -2;out[0]=std::uint8_t(result);out[1]=std::uint8_t(result>>8);return 2;
}
