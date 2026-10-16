module three_way_partition;

fn long three_way_partition(long* input, usz length, char* output, usz capacity) @export("three_way_partition") {
    if (input == null || length < 2 || length > 258) return -1;
    long n = input[0], pivot = input[1];
    if (n < 0 || n > 256 || length != (usz)(n + 2) || pivot < -2147483648 || pivot > 2147483647) return -1;
    int items[256];
    for (usz i=0; i<(usz)n; i++) { long x=input[i+2]; if(x < -2147483648 || x > 2147483647) return -1; items[i]=(int)x; }
    usz low=0, mid=0, high=(usz)n;
    while(mid<high) { if(items[mid]<pivot){int t=items[low];items[low++]=items[mid];items[mid++]=t;} else if(items[mid]>pivot){int t=items[mid];items[mid]=items[--high];items[high]=t;} else mid++; }
    usz bytes=((usz)n+2)*4; if(capacity<bytes)return -2;
    int* out=(int*)output; for(usz i=0;i<(usz)n;i++)out[i]=items[i]; out[n]=(int)low;out[n+1]=(int)high;
    return n+2;
}
