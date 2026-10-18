#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 4u
#define MAX_INPUT 19u

static double add(double a,double b){volatile double v=a+b;return v;}
static double mul(double a,double b){volatile double v=a*b;return v;}
static double divv(double a,double b){volatile double v=a/b;return v;}

int64_t page_rank_java(const double *input,size_t input_length,double *output,size_t output_capacity)
{
    if(input==NULL||input_length<3||input_length>MAX_INPUT)return -1;
    for(size_t i=0;i<input_length;i++)if(!isfinite(input[i]))return -1;
    if(input[0]<1.0||input[0]>4.0||input[0]!=(double)(size_t)input[0]||
       input[1]<1.0||input[1]>8.0||input[1]!=(double)(size_t)input[1])return -1;
    size_t nodes=(size_t)input[0],iterations=(size_t)input[1];
    if(input_length!=2+nodes*nodes)return -1;
    int matrix[MAX_NODES*MAX_NODES]={0};size_t outdegree[MAX_NODES]={0};
    for(size_t i=0;i<nodes*nodes;i++){
        if(input[2+i]!=0.0&&input[2+i]!=1.0)return -1;matrix[i]=(int)input[2+i];
    }
    for(size_t node=0;node<nodes;node++){
        if(matrix[node*nodes+node]!=0)return -1;
        for(size_t target=0;target<nodes;target++)outdegree[node]+=(size_t)matrix[node*nodes+target];
    }
    double ranks[MAX_NODES],next[MAX_NODES];
    for(size_t node=0;node<nodes;node++)ranks[node]=divv(1.0,(double)nodes);
    for(size_t iteration=0;iteration<iterations;iteration++){
        for(size_t target=0;target<nodes;target++){
            double incoming=0.0;
            for(size_t source=0;source<nodes;source++)if(matrix[source*nodes+target]==1&&outdegree[source]>0){
                double share=divv(ranks[source],(double)outdegree[source]);
                incoming=add(incoming,share);
            }
            next[target]=add(1.0-0.5,mul(0.5,incoming));
        }
        for(size_t node=0;node<nodes;node++)ranks[node]=next[node];
    }
    double staged[MAX_NODES];for(size_t node=0;node<nodes;node++)staged[node]=ranks[node];
    if(output==NULL||output_capacity<nodes)return -2;
    for(size_t node=0;node<nodes;node++)output[node]=staged[node];
    return (int64_t)nodes;
}
