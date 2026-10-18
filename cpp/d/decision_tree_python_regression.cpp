#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples=12,max_queries=12,max_input=41,max_output=13,max_tree_nodes=23;
struct TreeNode{double prediction,boundary;int left,right;bool leaf;};
double sum_range(const double* values,std::size_t start,std::size_t end) noexcept {double sum=0.0;for(std::size_t i=start;i<end;i++)sum+=values[i];return sum;}
double mean_range(const double* values,std::size_t start,std::size_t end) noexcept {return sum_range(values,start,end)/static_cast<double>(end-start);}
double mse_against(const double* values,std::size_t start,std::size_t end,double prediction) noexcept {
    double sum=0.0;for(std::size_t i=start;i<end;i++){const double delta=values[i]-prediction;sum+=delta*delta;}return sum/static_cast<double>(end-start);
}
int build_tree(TreeNode* nodes,std::size_t& used,const double* x,const double* y,
               std::size_t start,std::size_t end,std::size_t min_leaf,int depth) noexcept {
    if(used>=max_tree_nodes)return -1;
    const int current=static_cast<int>(used++);const std::size_t length=end-start;
    nodes[current]={mean_range(y,start,end),0.0,-1,-1,true};
    if(length<2*min_leaf||depth==1)return current;
    double min_error=2.0*mse_against(x,start,end,nodes[current].prediction);std::size_t best_split=0;
    for(std::size_t split=0;split<length;split++){
        const std::size_t right_count=length-split;
        if(split<min_leaf||right_count<min_leaf)continue;
        const double left_mean=mean_range(y,start,start+split),right_mean=mean_range(y,start+split,end);
        const double error=mse_against(x,start,start+split,left_mean)+mse_against(x,start+split,end,right_mean);
        if(error<min_error){best_split=split;min_error=error;}
    }
    if(best_split==0)return current;
    nodes[current].leaf=false;nodes[current].boundary=x[start+best_split];
    const int left=build_tree(nodes,used,x,y,start,start+best_split,min_leaf,depth-1);if(left<0)return -1;
    const int right=build_tree(nodes,used,x,y,start+best_split,end,min_leaf,depth-1);if(right<0)return -1;
    nodes[current].left=left;nodes[current].right=right;return current;
}
double predict(const TreeNode* nodes,int node,double query) noexcept {
    while(!nodes[node].leaf)node=query>=nodes[node].boundary?nodes[node].right:nodes[node].left;
    return nodes[node].prediction;
}
bool integer_in_range(double value,int minimum,int maximum) noexcept {
    return std::isfinite(value)&&value>=minimum&&value<=maximum&&value==std::trunc(value);
}
}

extern "C" std::int64_t decision_tree_python_regression(const double* input,std::size_t input_length,
    double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<8||input_length>max_input)return -1;
    for(std::size_t i=0;i<input_length;i++)if(!std::isfinite(input[i]))return -1;
    if(!integer_in_range(input[0],1,6)||!integer_in_range(input[1],1,6)||!integer_in_range(input[2],2,12))return -1;
    const int depth=static_cast<int>(input[0]);const auto min_leaf=static_cast<std::size_t>(input[1]),samples=static_cast<std::size_t>(input[2]);
    const std::size_t query_index=3+2*samples;
    if(input_length<=query_index||!integer_in_range(input[query_index],1,12))return -1;
    const auto query_count=static_cast<std::size_t>(input[query_index]);
    if(input_length!=query_index+1+query_count||input_length>40)return -1;
    double x[max_samples],y[max_samples],queries[max_queries];
    for(std::size_t i=0;i<samples;i++){
        x[i]=input[3+i];y[i]=input[3+samples+i];
        if(x[i]<-8.0||x[i]>8.0||x[i]!=std::trunc(x[i])||y[i]<-8.0||y[i]>8.0||y[i]!=std::trunc(y[i]))return -1;
    }
    for(std::size_t i=0;i<query_count;i++){
        queries[i]=input[query_index+1+i];if(queries[i]<-8.0||queries[i]>8.0||queries[i]!=std::trunc(queries[i]))return -1;
    }
    TreeNode nodes[max_tree_nodes];std::size_t used=0;const int root=build_tree(nodes,used,x,y,0,samples,min_leaf,depth);if(root<0)return -1;
    double staged[max_output];staged[0]=static_cast<double>(query_count);
    for(std::size_t i=0;i<query_count;i++)staged[i+1]=predict(nodes,root,queries[i]);
    if(output==nullptr||output_capacity<query_count+1)return -2;
    for(std::size_t i=0;i<query_count+1;i++)output[i]=staged[i];
    return static_cast<std::int64_t>(query_count+1);
}
