module median_heap;

const usz MAX_OPERATIONS = 256;
const usz MAX_INPUT_LENGTH = 514;
const usz MAX_LIVE_VALUES = 64;
const long NIL_SENTINEL = -9223372036854775807 - 1;

void store_i64_le(char* output, usz offset, long value) { ulong bits=@bitcast(ulong,value);for(usz b=0;b<8;b++)output[offset+b]=(char)(bits>>(8*b)); }
void push_max(int* heap, usz* count, int value){usz p=(*count)++;while(p>0&&heap[(p-1)/2]<value){usz q=(p-1)/2;heap[p]=heap[q];p=q;}heap[p]=value;}
int pop_max(int* heap, usz* count){int r=heap[0],x=heap[--(*count)];if(*count==0)return r;usz p=0;while(2*p+1<*count){usz c=2*p+1;if(c+1<*count&&heap[c+1]>heap[c])c++;if(heap[c]<=x)break;heap[p]=heap[c];p=c;}heap[p]=x;return r;}
void push_min(int* heap, usz* count, int value){usz p=(*count)++;while(p>0&&heap[(p-1)/2]>value){usz q=(p-1)/2;heap[p]=heap[q];p=q;}heap[p]=value;}
int pop_min(int* heap, usz* count){int r=heap[0],x=heap[--(*count)];if(*count==0)return r;usz p=0;while(2*p+1<*count){usz c=2*p+1;if(c+1<*count&&heap[c+1]<heap[c])c++;if(heap[c]>=x)break;heap[p]=heap[c];p=c;}heap[p]=x;return r;}

fn long median_heap(long* input, usz length, char* output, usz capacity) @export("median_heap") {
    if(input==null||length<1||length>MAX_INPUT_LENGTH)return -1;
    long op_value=input[0];if(op_value<0||op_value>256||length!=1+2*(usz)op_value)return -1;usz count=(usz)op_value;
    int[MAX_LIVE_VALUES] lower=zeroed,upper=zeroed;usz lc=0,uc=0;long[MAX_OPERATIONS] results=zeroed;
    for(usz i=0;i<count;i++){long op=input[1+2*i],arg=input[2+2*i];
        if(op==0){if(arg< -2147483648||arg>2147483647||lc+uc>=MAX_LIVE_VALUES)return -1;int x=(int)arg;
            if(lc==0)push_max(&lower[0],&lc,x);else if(x<lower[0]){push_max(&lower[0],&lc,x);if(lc-uc>1)push_min(&upper[0],&uc,pop_max(&lower[0],&lc));}else{push_min(&upper[0],&uc,x);if(lc<uc)push_max(&lower[0],&lc,pop_min(&upper[0],&uc));}results[i]=NIL_SENTINEL;
        }else if(op>=1&&op<=4){if(arg!=0)return -1;if(op==1)results[i]=lc>0?(long)lower[0]:NIL_SENTINEL;
            else if(op==2){if(lc==0)results[i]=NIL_SENTINEL;else{results[i]=pop_max(&lower[0],&lc);if(lc<uc)push_max(&lower[0],&lc,pop_min(&upper[0],&uc));}}
            else if(op==3)results[i]=(long)(lc+uc);else results[i]=lc==0?1:0;
        }else return -1;
    }
    usz output_bytes=count*8;if(output==null||capacity<output_bytes)return -2;for(usz i=0;i<count;i++)store_i64_le(output,8*i,results[i]);return (long)output_bytes;
}
