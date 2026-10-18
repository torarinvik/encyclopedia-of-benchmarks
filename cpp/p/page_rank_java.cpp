#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes=4,max_input=19;
double add(double a,double b) noexcept { volatile double v=a+b;return v; }
double mul(double a,double b) noexcept { volatile double v=a*b;return v; }
double divv(double a,double b) noexcept { volatile double v=a/b;return v; }
}

extern "C" std::int64_t page_rank_java(const double* input,std::size_t input_length,
    double* output,std::size_t output_capacity) noexcept {
    if(input==nullptr||input_length<3||input_length>max_input)return -1;
    for(std::size_t i=0;i<input_length;i++)if(!std::isfinite(input[i]))return -1;
    if(input[0]<1.0||input[0]>4.0||input[0]!=static_cast<double>(static_cast<std::size_t>(input[0]))||
       input[1]<1.0||input[1]>8.0||input[1]!=static_cast<double>(static_cast<std::size_t>(input[1])))return -1;
    const auto nodes=static_cast<std::size_t>(input[0]),iterations=static_cast<std::size_t>(input[1]);
    if(input_length!=2+nodes*nodes)return -1;
    int matrix[max_nodes*max_nodes]{};std::size_t outdegree[max_nodes]{};
    for(std::size_t i=0;i<nodes*nodes;i++){
        if(input[2+i]!=0.0&&input[2+i]!=1.0)return -1;matrix[i]=static_cast<int>(input[2+i]);
    }
    for(std::size_t node=0;node<nodes;node++){
        if(matrix[node*nodes+node]!=0)return -1;
        for(std::size_t target=0;target<nodes;target++)outdegree[node]+=static_cast<std::size_t>(matrix[node*nodes+target]);
    }
    double ranks[max_nodes],next[max_nodes];
    for(std::size_t node=0;node<nodes;node++)ranks[node]=divv(1.0,static_cast<double>(nodes));
    for(std::size_t iteration=0;iteration<iterations;iteration++){
        for(std::size_t target=0;target<nodes;target++){
            double incoming=0.0;
            for(std::size_t source=0;source<nodes;source++)if(matrix[source*nodes+target]==1&&outdegree[source]>0){
                const double share=divv(ranks[source],static_cast<double>(outdegree[source]));
                incoming=add(incoming,share);
            }
            next[target]=add(1.0-0.5,mul(0.5,incoming));
        }
        for(std::size_t node=0;node<nodes;node++)ranks[node]=next[node];
    }
    double staged[max_nodes];for(std::size_t node=0;node<nodes;node++)staged[node]=ranks[node];
    if(output==nullptr||output_capacity<nodes)return -2;
    for(std::size_t node=0;node<nodes;node++)output[node]=staged[node];
    return static_cast<std::int64_t>(nodes);
}
