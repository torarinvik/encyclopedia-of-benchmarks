#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t max_nodes=100;
bool validate(const std::int64_t*n,std::size_t count,std::int64_t node,bool*seen,std::size_t&reached){if(node==-1)return true;if(node<0||static_cast<std::uint64_t>(node)>=count)return false;auto i=static_cast<std::size_t>(node);if(seen[i])return false;seen[i]=true;++reached;auto v=n[3*i],l=n[3*i+1],r=n[3*i+2];if(v<INT32_MIN||v>INT32_MAX||l< -1||r< -1||(l>=0&&static_cast<std::uint64_t>(l)>=count)||(r>=0&&static_cast<std::uint64_t>(r)>=count))return false;return validate(n,count,l,seen,reached)&&validate(n,count,r,seen,reached);}
bool leaf(const std::int64_t*n,std::size_t i){return n[3*i+1]==-1&&n[3*i+2]==-1;}
void emit_leaves(const std::int64_t*n,std::int64_t node,std::int64_t*out,std::size_t&used){if(node==-1)return;auto i=static_cast<std::size_t>(node);if(leaf(n,i)){out[used++]=n[3*i];return;}emit_leaves(n,n[3*i+1],out,used);emit_leaves(n,n[3*i+2],out,used);}
}
extern "C" std::int64_t boundary_traversal(const std::int64_t*n,std::size_t count,std::int64_t root,std::int64_t*out,std::size_t cap) noexcept{
 if(count>max_nodes||cap<count)return -1;if(count==0)return root==-1?0:-1;if(!n||!out||root<0||static_cast<std::uint64_t>(root)>=count)return -1;
 bool seen[max_nodes]={};std::size_t reached=0;if(!validate(n,count,root,seen,reached)||reached!=count)return -1;
 std::size_t used=0,ri=static_cast<std::size_t>(root);if(!leaf(n,ri))out[used++]=n[3*ri];
 auto cur=n[3*ri+1];if(cur==-1&&n[3*ri+2]!=-1)cur=n[3*ri+2];
 while(cur!=-1){auto i=static_cast<std::size_t>(cur);if(!leaf(n,i))out[used++]=n[3*i];cur=n[3*i+1]!=-1?n[3*i+1]:n[3*i+2];}
 emit_leaves(n,root,out,used);if(n[3*ri+2]!=-1&&n[3*ri+1]==-1)return static_cast<std::int64_t>(used);
 std::int64_t right[max_nodes];std::size_t rn=0;cur=n[3*ri+2];while(cur!=-1){auto i=static_cast<std::size_t>(cur);if(!leaf(n,i))right[rn++]=n[3*i];cur=n[3*i+2]!=-1?n[3*i+2]:n[3*i+1];}while(rn>0)out[used++]=right[--rn];return static_cast<std::int64_t>(used);
}
