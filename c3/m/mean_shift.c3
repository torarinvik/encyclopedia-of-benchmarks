module mean_shift;

const usz MAX_POINTS=16;
const usz MAX_DIMENSION=3;
const usz MAX_INPUT_LENGTH=54;
const double MARGIN=0.000001;
extern fn double trunc(double value);
extern fn double fabs(double value);
extern fn double pow(double base, double exponent);

double distance(double* a,double* b,usz dimensions){double sum=0.0;for(usz d=0;d<dimensions;d++){double diff=a[d]-b[d];sum+=diff*diff;}return pow(sum,0.5);}
bool near_threshold(double value,double threshold){return fabs(value-threshold)<MARGIN;}

fn long mean_shift(double* input,usz length,double* output,usz capacity) @export("mean_shift") {
    if(input==null||length<5||length>MAX_INPUT_LENGTH)return -1;
    for(usz i=0;i<length;i++)if(input[i]!=input[i])return -1;
    double n_value=input[0],dim_value=input[1],bandwidth=input[2],iteration_value=input[3],tolerance=input[4];
    if(trunc(n_value)!=n_value||trunc(dim_value)!=dim_value||trunc(iteration_value)!=iteration_value)return -1;
    if(n_value<1.0||n_value>16.0||dim_value<1.0||dim_value>3.0||iteration_value<1.0||iteration_value>64.0||bandwidth<0.5||bandwidth>20.0||tolerance<0.00001||tolerance>0.01)return -1;
    usz n=(usz)n_value,dimensions=(usz)dim_value,max_iterations=(usz)iteration_value;if(length!=5+n*dimensions)return -1;double* data=input+5;
    for(usz i=0;i<n*dimensions;i++)if(data[i]< -10.0||data[i]>10.0)return -1;
    double[MAX_POINTS*MAX_DIMENSION] candidates=zeroed,next=zeroed;
    for(usz i=0;i<n*dimensions;i++)candidates[i]=data[i];
    for(usz iteration=0;iteration<max_iterations;iteration++){
        for(usz c=0;c<n;c++){double[MAX_DIMENSION] sums=zeroed;usz neighbors=0;
            for(usz p=0;p<n;p++){double dist=distance(data+p*dimensions,&candidates[c*dimensions],dimensions);if(near_threshold(dist,bandwidth))return -1;if(dist<=bandwidth){neighbors++;for(usz d=0;d<dimensions;d++)sums[d]+=data[p*dimensions+d];}}
            for(usz d=0;d<dimensions;d++)next[c*dimensions+d]=neighbors==0?candidates[c*dimensions+d]:sums[d]/(double)neighbors;
        }
        bool all_converged=true;
        for(usz c=0;c<n;c++){double movement=distance(&candidates[c*dimensions],&next[c*dimensions],dimensions);if(near_threshold(movement,tolerance))return -1;if(movement>=tolerance){all_converged=false;break;}}
        if(all_converged)break;for(usz i=0;i<n*dimensions;i++)candidates[i]=next[i];
    }
    double[MAX_POINTS*MAX_DIMENSION] centroids=zeroed;usz centroid_count=0;
    for(usz c=0;c<n;c++){bool keep=true;for(usz e=0;e<centroid_count;e++){double dist=distance(&candidates[c*dimensions],&centroids[e*dimensions],dimensions);if(near_threshold(dist,bandwidth))return -1;if(dist<bandwidth){keep=false;break;}}if(keep){for(usz d=0;d<dimensions;d++)centroids[centroid_count*dimensions+d]=candidates[c*dimensions+d];centroid_count++;}}
    double[MAX_POINTS] labels=zeroed;
    for(usz p=0;p<n;p++){usz best=0;double best_distance=distance(data+p*dimensions,&centroids[0],dimensions);for(usz c=1;c<centroid_count;c++){double dist=distance(data+p*dimensions,&centroids[c*dimensions],dimensions);if(dist!=best_distance&&near_threshold(dist,best_distance))return -1;if(dist<best_distance){best=c;best_distance=dist;}}labels[p]=(double)best;}
    if(output==null||capacity<n)return -2;for(usz i=0;i<n;i++)output[i]=labels[i];return (long)n;
}
