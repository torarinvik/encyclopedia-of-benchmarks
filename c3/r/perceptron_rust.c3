module perceptron_rust;

const usz MAX_SAMPLES=8,MAX_FEATURES=4,MAX_QUERIES=4,MAX_INPUT=62,MAX_OUTPUT=11;
fn bool integer_range(double x,long lo,long hi){return x==x&&x>=(double)lo&&x<=(double)hi&&(double)(long)x==x;}
fn bool valid_rate(double x){return x==0.25||x==0.5||x==0.75||x==1.0;}

fn long perceptron_rust(double* input,usz length,double* output,usz capacity) @export("perceptron_rust") {
    if(input==null||length<9||length>MAX_INPUT)return -1L;
    for(usz i=0;i<length;i++)if(input[i]!=input[i])return -1L;
    if(!integer_range(input[0],0,12)||!valid_rate(input[1])||!integer_range(input[2],2,8)||!integer_range(input[3],1,4))return -1L;
    usz max_iterations=(usz)(long)input[0],n=(usz)(long)input[2],f=(usz)(long)input[3];double rate=input[1];
    usz labels_at=4+n*f,qidx=labels_at+n;if(length<=qidx||!integer_range(input[qidx],1,4))return -1L;
    usz q=(usz)(long)input[qidx];if(length!=qidx+1+q*f||length>61)return -1L;
    double[MAX_SAMPLES*MAX_FEATURES] x=zeroed;double[MAX_SAMPLES] labels=zeroed;double[MAX_QUERIES*MAX_FEATURES] queries=zeroed;
    for(usz i=0;i<n*f;i++){double v=input[4+i];if(!integer_range(v,-2,2))return -1L;x[i]=v;}
    for(usz i=0;i<n;i++){double v=input[labels_at+i];if(v!= -1.0&&v!=1.0)return -1L;labels[i]=v;}
    for(usz i=0;i<q*f;i++){double v=input[qidx+1+i];if(!integer_range(v,-2,2))return -1L;queries[i]=v;}
    double[MAX_FEATURES] weights=zeroed;double bias=0.0;
    for(usz iteration=0;iteration<max_iterations;iteration++){
        usz misclassified=0;
        for(usz row=0;row<n;row++){
            double score=0.0;for(usz j=0;j<f;j++)score+=weights[j]*x[row*f+j];score+=bias;
            double prediction=score>=0.0?1.0:-1.0;
            if(prediction!=labels[row]){misclassified++;for(usz j=0;j<f;j++)weights[j]+=rate*labels[row]*x[row*f+j];bias+=rate*labels[row];}
        }
        if(misclassified==0)break;
    }
    double[MAX_OUTPUT] staged=zeroed;usz pos=0;staged[pos++]=(double)f;for(usz j=0;j<f;j++)staged[pos++]=weights[j];staged[pos++]=bias;staged[pos++]=(double)q;
    for(usz row=0;row<q;row++){double score=0.0;for(usz j=0;j<f;j++)score+=weights[j]*queries[row*f+j];score+=bias;staged[pos++]=score>=0.0?1.0:-1.0;}
    if(output==null||capacity<pos)return -2L;for(usz i=0;i<pos;i++)output[i]=staged[i];return (long)pos;
}
