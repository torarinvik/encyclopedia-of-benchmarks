#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 12u
#define MAX_QUERIES 12u
#define MAX_INPUT 41u
#define MAX_OUTPUT 13u
#define MAX_TREE_NODES 23u

typedef struct { double prediction,boundary; int left,right; int is_leaf; } TreeNode;

static double sum_range(const double *values,size_t start,size_t end)
{
    double sum=0.0;for(size_t i=start;i<end;i++)sum+=values[i];return sum;
}
static double mean_range(const double *values,size_t start,size_t end)
{
    return sum_range(values,start,end)/(double)(end-start);
}
static double mse_against(const double *values,size_t start,size_t end,double prediction)
{
    double sum=0.0;
    for(size_t i=start;i<end;i++){double delta=values[i]-prediction;sum+=delta*delta;}
    return sum/(double)(end-start);
}
static int build_tree(TreeNode *nodes,size_t *used,const double *x,const double *y,
                      size_t start,size_t end,size_t min_leaf,int depth)
{
    if(*used>=MAX_TREE_NODES)return -1;
    int current=(int)(*used)++;size_t length=end-start;
    nodes[current].prediction=mean_range(y,start,end);nodes[current].boundary=0.0;
    nodes[current].left=nodes[current].right=-1;nodes[current].is_leaf=1;
    if(length<2*min_leaf||depth==1)return current;
    double min_error=2.0*mse_against(x,start,end,nodes[current].prediction);
    size_t best_split=0;
    for(size_t split=0;split<length;split++){
        size_t right_count=length-split;
        if(split<min_leaf||right_count<min_leaf)continue;
        double left_mean=mean_range(y,start,start+split);
        double right_mean=mean_range(y,start+split,end);
        double error=mse_against(x,start,start+split,left_mean)+mse_against(x,start+split,end,right_mean);
        if(error<min_error){best_split=split;min_error=error;}
    }
    if(best_split==0)return current;
    nodes[current].is_leaf=0;nodes[current].boundary=x[start+best_split];
    nodes[current].left=build_tree(nodes,used,x,y,start,start+best_split,min_leaf,depth-1);
    if(nodes[current].left<0)return -1;
    nodes[current].right=build_tree(nodes,used,x,y,start+best_split,end,min_leaf,depth-1);
    if(nodes[current].right<0)return -1;
    return current;
}
static double predict(const TreeNode *nodes,int node,double query)
{
    while(!nodes[node].is_leaf)node=query>=nodes[node].boundary?nodes[node].right:nodes[node].left;
    return nodes[node].prediction;
}
static int integer_in_range(double value,int minimum,int maximum)
{
    return isfinite(value)&&value>=(double)minimum&&value<=(double)maximum&&value==trunc(value);
}

int64_t decision_tree_python_regression(const double *input,size_t input_length,
                                        double *output,size_t output_capacity)
{
    if(input==NULL||input_length<8||input_length>MAX_INPUT)return -1;
    for(size_t i=0;i<input_length;i++)if(!isfinite(input[i]))return -1;
    if(!integer_in_range(input[0],1,6)||!integer_in_range(input[1],1,6)||
       !integer_in_range(input[2],2,12))return -1;
    int depth=(int)input[0];size_t min_leaf=(size_t)input[1],samples=(size_t)input[2];
    size_t query_count_index=3+2*samples;
    if(input_length<=query_count_index||!integer_in_range(input[query_count_index],1,12))return -1;
    size_t query_count=(size_t)input[query_count_index];
    if(input_length!=query_count_index+1+query_count||input_length>40)return -1;
    double x[MAX_SAMPLES],y[MAX_SAMPLES],queries[MAX_QUERIES];
    for(size_t i=0;i<samples;i++){
        x[i]=input[3+i];y[i]=input[3+samples+i];
        if(x[i]<-8.0||x[i]>8.0||x[i]!=trunc(x[i])||y[i]<-8.0||y[i]>8.0||y[i]!=trunc(y[i]))return -1;
    }
    for(size_t i=0;i<query_count;i++){
        queries[i]=input[query_count_index+1+i];
        if(queries[i]<-8.0||queries[i]>8.0||queries[i]!=trunc(queries[i]))return -1;
    }
    TreeNode nodes[MAX_TREE_NODES];size_t used=0;
    int root=build_tree(nodes,&used,x,y,0,samples,min_leaf,depth);
    if(root<0)return -1;
    double staged[MAX_OUTPUT];staged[0]=(double)query_count;
    for(size_t i=0;i<query_count;i++)staged[i+1]=predict(nodes,root,queries[i]);
    if(output==NULL||output_capacity<query_count+1)return -2;
    for(size_t i=0;i<query_count+1;i++)output[i]=staged[i];
    return (int64_t)(query_count+1);
}
