#include <array>
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_n=1024; }
extern "C" std::int64_t binary_tree_is_full(const std::int64_t* input,std::size_t length) noexcept {
    if(!input||length<2||input[0]<1||input[0]>static_cast<std::int64_t>(max_n))return -1;
    const int n=static_cast<int>(input[0]);const auto root_value=input[1];
    if(root_value<0||root_value>=n||length!=2+2*static_cast<std::size_t>(n))return -1;
    std::array<int,max_n> left{},right{},parents{},stack{};std::array<bool,max_n> seen{};bool full=true;
    for(int i=0;i<n;i++){auto l=input[2+2*i],r=input[3+2*i];if(l< -1||l>=n||r< -1||r>=n||l==i||r==i)return -1;left[i]=static_cast<int>(l);right[i]=static_cast<int>(r);if(l>=0)++parents[l];if(r>=0)++parents[r];if((l<0)!=(r<0))full=false;}
    const int root=static_cast<int>(root_value);if(parents[root]!=0)return -1;for(int i=0;i<n;i++)if(i!=root&&parents[i]!=1)return -1;
    int top=0,visited=0;stack[top++]=root;while(top){int node=stack[--top];if(seen[node])return -1;seen[node]=true;++visited;if(left[node]>=0)stack[top++]=left[node];if(right[node]>=0)stack[top++]=right[node];}
    if(visited!=n)return -1;return full?1:0;
}
