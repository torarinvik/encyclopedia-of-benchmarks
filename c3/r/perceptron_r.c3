module perceptron_r;

const usz MAX_SAMPLES=8,MAX_FEATURES=4,MAX_QUERIES=4,MAX_INPUT=62,MAX_OUTPUT=25;
fn bool integer_range(double x,long lo,long hi){return x==x&&x>=(double)lo&&x<=(double)hi&&(double)(long)x==x;}
fn bool valid_rate(double x){return x==0.25||x==0.5||x==0.75||x==1.0;}
fn double row_score(double* weights,double* row,usz width){double score=0.0;for(usz i=0;i<width;i++)score+=weights[i]*row[i];return score;}

fn long perceptron_r(double* input,usz length,double* output,usz capacity) @export("perceptron_r") {
    if(input==null||length<8||length>MAX_INPUT)return -1L;
    for(usz i=0;i<length;i++)if(input[i]!=input[i])return -1L;
    if(!valid_rate(input[0])||!integer_range(input[1],1,12)||!integer_range(input[2],2,8)||!integer_range(input[3],1,4))return -1L;
    double rate=input[0];usz epochs=(usz)(long)input[1],n=(usz)(long)input[2],f=(usz)(long)input[3];
    usz labels_at=4+n*f,qidx=labels_at+n;if(length<=qidx||!integer_range(input[qidx],1,4))return -1L;
    usz q=(usz)(long)input[qidx];if(length!=qidx+1+q*f||length>61)return -1L;
    double[MAX_SAMPLES*MAX_FEATURES] x=zeroed;double[MAX_SAMPLES] labels=zeroed;double[MAX_QUERIES*MAX_FEATURES] queries=zeroed;
    for(usz i=0;i<n*f;i++){double v=input[4+i];if(!integer_range(v,-2,2))return -1L;x[i]=v;}
    for(usz i=0;i<n;i++){double v=input[labels_at+i];if(!integer_range(v,-2,2))return -1L;labels[i]=v;}
    for(usz i=0;i<q*f;i++){double v=input[qidx+1+i];if(!integer_range(v,-2,2))return -1L;queries[i]=v;}
    double[3] classes=zeroed;usz class_count=0;
    for(long value=-2;value<=2;value++){bool seen=false;for(usz i=0;i<n;i++)if(labels[i]==(double)value){seen=true;break;}if(seen)classes[class_count++]=(double)value;}
    if(class_count<2||class_count>3)return -1L;
    double[MAX_SAMPLES*(MAX_FEATURES+1)] rows=zeroed;
    double[MAX_QUERIES*(MAX_FEATURES+1)] query_rows=zeroed;
    for(usz r=0;r<n;r++){rows[r*(f+1)]=1.0;for(usz j=0;j<f;j++)rows[r*(f+1)+j+1]=x[r*f+j];}
    for(usz r=0;r<q;r++){query_rows[r*(f+1)]=1.0;for(usz j=0;j<f;j++)query_rows[r*(f+1)+j+1]=queries[r*f+j];}
    double[3*(MAX_FEATURES+1)] weights=zeroed;
    if(class_count==2){
        for(usz e=0;e<epochs;e++)for(usz r=0;r<n;r++){
            double label=labels[r]==classes[0]?-1.0:1.0;double value=row_score(&weights[0],&rows[r*(f+1)],f+1);
            if(label*value<=0.0)for(usz j=0;j<f+1;j++)weights[j]+=rate*label*rows[r*(f+1)+j];
        }
    }else{
        for(usz e=0;e<epochs;e++)for(usz r=0;r<n;r++){
            double[3] scores=zeroed;for(usz c=0;c<class_count;c++)scores[c]=row_score(&weights[c*(f+1)],&rows[r*(f+1)],f+1);
            usz predicted=0;for(usz c=1;c<class_count;c++)if(scores[c]>scores[predicted])predicted=c;
            usz target=0;while(target<class_count&&labels[r]!=classes[target])target++;
            if(predicted!=target)for(usz j=0;j<f+1;j++){double update=rate*rows[r*(f+1)+j];weights[target*(f+1)+j]+=update;weights[predicted*(f+1)+j]-=update;}
        }
    }
    double[MAX_OUTPUT] staged=zeroed;usz pos=0;staged[pos++]=(double)class_count;
    for(usz c=0;c<class_count;c++)staged[pos++]=classes[c];
    usz parameter_count=class_count==2?f+1:class_count*(f+1);staged[pos++]=(double)parameter_count;
    if(class_count==2){for(usz j=0;j<f+1;j++)staged[pos++]=weights[j];}
    else for(usz c=0;c<class_count;c++)for(usz j=0;j<f+1;j++)staged[pos++]=weights[c*(f+1)+j];
    staged[pos++]=(double)q;
    for(usz r=0;r<q;r++){
        usz predicted=0;
        if(class_count==2)predicted=row_score(&weights[0],&query_rows[r*(f+1)],f+1)>=0.0?1:0;
        else{double[3] scores=zeroed;for(usz c=0;c<class_count;c++)scores[c]=row_score(&weights[c*(f+1)],&query_rows[r*(f+1)],f+1);for(usz c=1;c<class_count;c++)if(scores[c]>scores[predicted])predicted=c;}
        staged[pos++]=classes[predicted];
    }
    if(output==null||capacity<pos)return -2L;for(usz i=0;i<pos;i++)output[i]=staged[i];return (long)pos;
}
