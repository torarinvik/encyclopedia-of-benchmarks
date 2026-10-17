module median_of_running_array_float;

const usz MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = 66;

bool less_float(float left, float right) {
    if (left < right) return true;
    if (left == 0.0 && right == 0.0) return ((@bitcast(uint, left) >> 31) != 0) && ((@bitcast(uint, right) >> 31) == 0);
    return false;
}
void push_max(float* heap, usz* count, float value) { usz p=(*count)++;while(p>0&&less_float(heap[(p-1)/2],value)){usz parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
float pop_max(float* heap, usz* count) { float result=heap[0],value=heap[--(*count)];if(*count==0)return result;usz p=0;while(2*p+1<*count){usz child=2*p+1;if(child+1<*count&&less_float(heap[child],heap[child+1]))child++;if(!less_float(value,heap[child]))break;heap[p]=heap[child];p=child;}heap[p]=value;return result; }
void push_min(float* heap, usz* count, float value) { usz p=(*count)++;while(p>0&&less_float(value,heap[(p-1)/2])){usz parent=(p-1)/2;heap[p]=heap[parent];p=parent;}heap[p]=value; }
float pop_min(float* heap, usz* count) { float result=heap[0],value=heap[--(*count)];if(*count==0)return result;usz p=0;while(2*p+1<*count){usz child=2*p+1;if(child+1<*count&&less_float(heap[child+1],heap[child]))child++;if(!less_float(heap[child],value))break;heap[p]=heap[child];p=child;}heap[p]=value;return result; }

fn long median_of_running_array_float(double* input, usz length, double* output, usz capacity)
    @export("median_of_running_array_float") {
    if(input==null||length<1||length>MAX_INPUT_LENGTH)return -1;
    double count_value=input[0];
    if(count_value!=count_value||count_value<1.0||count_value>64.0||(double)(usz)count_value!=count_value||length!=1+(usz)count_value)return -1;
    usz count=(usz)count_value;float[MAX_COUNT] lower=zeroed,upper=zeroed,medians=zeroed;usz lc=0,uc=0;
    for(usz i=0;i<count;i++){
        double sample=input[i+1];if(sample!=sample||sample< -1000000.0||sample>1000000.0)return -1;float x=(float)sample;
        if((double)x!=sample||(sample==0.0&&((uint)(@bitcast(ulong,sample)>>63)!=(@bitcast(uint,x)>>31))))return -1;
        if(uc>0&&less_float(x,upper[0]))push_max(&lower[0],&lc,x);else push_min(&upper[0],&uc,x);
        if(lc>uc+1)push_min(&upper[0],&uc,pop_max(&lower[0],&lc));else if(uc>lc+1)push_max(&lower[0],&lc,pop_min(&upper[0],&uc));
        if(lc>uc)medians[i]=lower[0];else if(uc>lc)medians[i]=upper[0];else{float sum=lower[0]+upper[0];float average=sum/2.0;medians[i]=average;}
    }
    if(output==null||capacity<count)return -2;for(usz i=0;i<count;i++)output[i]=(double)medians[i];return (long)count;
}
