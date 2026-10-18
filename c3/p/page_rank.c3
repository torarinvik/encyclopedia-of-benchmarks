module page_rank;

const usz MAX_NODES=4;
const usz MAX_INPUT=19;

fn bool finite_value(double x) { return x==x && x<1e300 && x> -1e300; }

fn long page_rank(double* input,usz input_length,double* output,usz output_capacity) @export("page_rank") {
    if(input==null || input_length<6 || input_length>MAX_INPUT) return -1L;
    for(usz i=0;i<input_length;i++) if(!finite_value(input[i])) return -1L;
    if(input[0]<2.0 || input[0]>4.0 || (double)(long)input[0]!=input[0] ||
       input[1]<0.0 || input[1]>8.0 || (double)(long)input[1]!=input[1]) return -1L;
    usz nodes=(usz)(long)input[0], iterations=(usz)(long)input[1];
    if(input_length!=2+nodes*nodes) return -1L;
    long[16] matrix=zeroed; usz[4] outdegree=zeroed;
    for(usz i=0;i<nodes*nodes;i++) {
        if(input[2+i]!=0.0 && input[2+i]!=1.0) return -1L;
        matrix[i]=(long)input[2+i];
    }
    for(usz node=0;node<nodes;node++) {
        if(matrix[node*nodes+node]!=0) return -1L;
        for(usz target=0;target<nodes;target++) outdegree[node]+=(usz)matrix[node*nodes+target];
    }
    double[4] ranks=zeroed, next=zeroed;
    for(usz node=0;node<nodes;node++) ranks[node]=1.0/(double)nodes;
    double base_random_jump=(1.0-0.5)/(double)nodes;
    for(usz iteration=0;iteration<iterations;iteration++) {
        double dangling_sum=0.0;
        for(usz node=0;node<nodes;node++) if(outdegree[node]==0) dangling_sum+=ranks[node];
        double dangling_share=(dangling_sum*0.5)/(double)nodes;
        double base_rank=base_random_jump+dangling_share;
        for(usz target=0;target<nodes;target++) {
            double incoming=0.0;
            for(usz source=0;source<nodes;source++) if(matrix[source*nodes+target]==1) {
                double share=ranks[source]/(double)outdegree[source];
                incoming+=share;
            }
            next[target]=base_rank+incoming*0.5;
        }
        for(usz node=0;node<nodes;node++) ranks[node]=next[node];
    }
    double[4] staged=zeroed;
    for(usz node=0;node<nodes;node++) staged[node]=ranks[node];
    if(output==null || output_capacity<nodes) return -2L;
    for(usz node=0;node<nodes;node++) output[node]=staged[node];
    return (long)nodes;
}
