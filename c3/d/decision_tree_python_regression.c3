module decision_tree_python_regression;

const usz MAX_SAMPLES=12;
const usz MAX_QUERIES=12;
const usz MAX_INPUT=41;
const usz MAX_OUTPUT=13;
const usz MAX_TREE_NODES=23;

struct TreeNode { double prediction; double boundary; int left; int right; bool leaf; }

fn double sum_range(double* values,usz start,usz end) {
    double sum=0.0;
    for(usz i=start;i<end;i++) sum+=values[i];
    return sum;
}
fn double mean_range(double* values,usz start,usz end) {
    return sum_range(values,start,end)/(double)(end-start);
}
fn double mse_against(double* values,usz start,usz end,double prediction) {
    double sum=0.0;
    for(usz i=start;i<end;i++) { double delta=values[i]-prediction;sum+=delta*delta; }
    return sum/(double)(end-start);
}
fn int build_tree(TreeNode* nodes,usz* used,double* x,double* y,usz start,usz end,usz min_leaf,int depth) {
    if(*used>=MAX_TREE_NODES)return -1;
    int current=(int)(*used);(*used)++;
    usz length=end-start;
    nodes[current]={mean_range(y,start,end),0.0,-1,-1,true};
    if(length<2*min_leaf||depth==1)return current;
    double min_error=2.0*mse_against(x,start,end,nodes[current].prediction);
    usz best_split=0;
    for(usz split=0;split<length;split++) {
        usz right_count=length-split;
        if(split<min_leaf||right_count<min_leaf)continue;
        double left_mean=mean_range(y,start,start+split);
        double right_mean=mean_range(y,start+split,end);
        double error=mse_against(x,start,start+split,left_mean)+mse_against(x,start+split,end,right_mean);
        if(error<min_error){best_split=split;min_error=error;}
    }
    if(best_split==0)return current;
    nodes[current].leaf=false;nodes[current].boundary=x[start+best_split];
    int left=build_tree(nodes,used,x,y,start,start+best_split,min_leaf,depth-1);
    if(left<0)return -1;
    int right=build_tree(nodes,used,x,y,start+best_split,end,min_leaf,depth-1);
    if(right<0)return -1;
    nodes[current].left=left;nodes[current].right=right;
    return current;
}
fn double predict(TreeNode* nodes,int node,double query) {
    while(!nodes[node].leaf) {
        if(query>=nodes[node].boundary)node=nodes[node].right;
        else node=nodes[node].left;
    }
    return nodes[node].prediction;
}
fn bool integer_in_range(double value,double minimum,double maximum) {
    return value==value&&value>=minimum&&value<=maximum&&(double)(long)value==value;
}

fn long decision_tree_python_regression(double* input,usz input_length,double* output,usz output_capacity)
    @export("decision_tree_python_regression") {
    if(input==null||input_length<8||input_length>MAX_INPUT)return -1L;
    for(usz i=0;i<input_length;i++)if(input[i]!=input[i])return -1L;
    if(!integer_in_range(input[0],1.0,6.0)||!integer_in_range(input[1],1.0,6.0)||
       !integer_in_range(input[2],2.0,12.0))return -1L;
    int depth=(int)(long)input[0];usz min_leaf=(usz)(long)input[1],samples=(usz)(long)input[2];
    usz query_index=3+2*samples;
    if(input_length<=query_index||!integer_in_range(input[query_index],1.0,12.0))return -1L;
    usz query_count=(usz)(long)input[query_index];
    if(input_length!=query_index+1+query_count||input_length>40)return -1L;
    double[MAX_SAMPLES] x=zeroed,y=zeroed;
    double[MAX_QUERIES] queries=zeroed;
    for(usz i=0;i<samples;i++) {
        x[i]=input[3+i];y[i]=input[3+samples+i];
        if(!integer_in_range(x[i],-8.0,8.0)||!integer_in_range(y[i],-8.0,8.0))return -1L;
    }
    for(usz i=0;i<query_count;i++) {
        queries[i]=input[query_index+1+i];
        if(!integer_in_range(queries[i],-8.0,8.0))return -1L;
    }
    TreeNode[MAX_TREE_NODES] nodes=zeroed;usz used=0;
    int root=build_tree(&nodes[0],&used,&x[0],&y[0],0,samples,min_leaf,depth);
    if(root<0)return -1L;
    double[MAX_OUTPUT] staged=zeroed;staged[0]=(double)query_count;
    for(usz i=0;i<query_count;i++)staged[i+1]=predict(&nodes[0],root,queries[i]);
    if(output==null||output_capacity<query_count+1)return -2L;
    for(usz i=0;i<query_count+1;i++)output[i]=staged[i];
    return (long)(query_count+1);
}
