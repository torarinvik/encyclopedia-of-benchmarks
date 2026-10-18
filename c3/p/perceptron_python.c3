module perceptron_python;

const usz MAX_SAMPLES=8,MAX_FEATURES=4,MAX_QUERIES=4,MAX_INPUT=62,MAX_OUTPUT=12;
const double[4] INITIAL_RANDOM={0.8444218515250481,0.7579544029403025,0.420571580830845,0.25891675029296335};

fn bool integer_range(double x,long lo,long hi){return x==x&&x>=(double)lo&&x<=(double)hi&&(double)(long)x==x;}
fn bool valid_rate(double x){return x==0.25||x==0.5||x==0.75||x==1.0;}

fn long perceptron_python(double* input,usz length,double* output,usz capacity) @export("perceptron_python") {
    if(input==null||length<9||length>MAX_INPUT)return -1L;
    for(usz i=0;i<length;i++)if(input[i]!=input[i])return -1L;
    if(!valid_rate(input[0])||!integer_range(input[1],1,12)||!integer_range(input[2],2,8)||!integer_range(input[3],1,4))return -1L;
    double rate=input[0];usz epochs=(usz)(long)input[1],n=(usz)(long)input[2],f=(usz)(long)input[3];
    usz labels_at=4+n*f,qidx=labels_at+n;
    if(length<=qidx||!integer_range(input[qidx],1,4))return -1L;
    usz q=(usz)(long)input[qidx];if(length!=qidx+1+q*f||length>61)return -1L;
    double[MAX_SAMPLES*MAX_FEATURES] x=zeroed;double[MAX_SAMPLES] y=zeroed;double[MAX_QUERIES*MAX_FEATURES] queries=zeroed;
    for(usz i=0;i<n*f;i++){double v=input[4+i];if(!integer_range(v,-2,2))return -1L;x[i]=v;}
    for(usz i=0;i<n;i++){double v=input[labels_at+i];if(v!= -1.0&&v!=1.0)return -1L;y[i]=v;}
    for(usz i=0;i<q*f;i++){double v=input[qidx+1+i];if(!integer_range(v,-2,2))return -1L;queries[i]=v;}
    double[5] weights={-1.0,0.0,0.0,0.0,0.0};for(usz j=0;j<f;j++)weights[j+1]=INITIAL_RANDOM[j];
    usz epochs_run=0;
    for(usz epoch=0;epoch<epochs;epoch++){
        bool mistake=false;
        for(usz row=0;row<n;row++){
            double score=0.0;score+=weights[0]*(-1.0);
            for(usz j=0;j<f;j++)score+=weights[j+1]*x[row*f+j];
            double prediction=score>=0.0?1.0:-1.0;
            if(prediction!=y[row]){
                double error=y[row]-prediction;mistake=true;double scale=rate*error;
                weights[0]+=scale*(-1.0);for(usz j=0;j<f;j++)weights[j+1]+=scale*x[row*f+j];
            }
        }
        epochs_run=epoch+1;if(!mistake)break;
    }
    double[MAX_OUTPUT] staged=zeroed;usz pos=0;staged[pos++]=(double)epochs_run;staged[pos++]=(double)(f+1);
    for(usz j=0;j<=f;j++)staged[pos++]=weights[j];staged[pos++]=(double)q;
    for(usz row=0;row<q;row++){
        double score=weights[0]*(-1.0);for(usz j=0;j<f;j++)score+=weights[j+1]*queries[row*f+j];
        staged[pos++]=score>=0.0?1.0:-1.0;
    }
    if(output==null||capacity<pos)return -2L;for(usz i=0;i<pos;i++)output[i]=staged[i];return (long)pos;
}
