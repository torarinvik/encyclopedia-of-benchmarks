#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_NODES = 400;
constexpr std::int64_t INVALID_RESULT = INT64_C(-9000000000000000000);
std::int64_t subtree_sum(const std::int64_t *nodes, std::int64_t index) {
    if (index < 0) return 0;
    return nodes[3*index] + subtree_sum(nodes,nodes[3*index+1]) + subtree_sum(nodes,nodes[3*index+2]);
}
bool check_node(const std::int64_t *nodes, std::int64_t index) {
    const auto value=nodes[3*index], left=nodes[3*index+1], right=nodes[3*index+2];
    if(left==-1 && right==-1)return true;
    const auto left_sum=subtree_sum(nodes,left), right_sum=subtree_sum(nodes,right);
    const bool left_ok=left==-1 || check_node(nodes,left);
    const bool right_ok=right==-1 || check_node(nodes,right);
    return value==left_sum+right_sum && left_ok && right_ok;
}
}
extern "C" std::int64_t is_sum_tree(const std::int64_t *nodes, std::size_t count, std::int64_t root) {
    if(!nodes||count==0||count>MAX_NODES||root<0||std::uint64_t(root)>=count)return INVALID_RESULT;
    bool seen[MAX_NODES]={};std::int64_t stack[MAX_NODES*2];std::size_t top=0;stack[top++]=root;
    while(top){const auto i=stack[--top];if(i<0||std::uint64_t(i)>=count||seen[i])return INVALID_RESULT;seen[i]=true;
        const auto value=nodes[3*i],l=nodes[3*i+1],r=nodes[3*i+2];
        if(value < -1000000000||value>1000000000||l < -1||r < -1||(l>=0&&std::uint64_t(l)>=count)||(r>=0&&std::uint64_t(r)>=count))return INVALID_RESULT;
        if(l>=0)stack[top++]=l;if(r>=0)stack[top++]=r;
    }
    return check_node(nodes,root)?1:0;
}
