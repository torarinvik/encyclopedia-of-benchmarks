module all_farthest_neighbors_convex;

struct Point { long x; long y; }
fn long score(Point* points, int n, int row, int col) {
    if (col <= row) return col-row;
    if (col >= row+n) return -1;
    long dx=points[row].x-points[col%n].x, dy=points[row].y-points[col%n].y;
    return dx*dx+dy*dy;
}
fn void maxima(Point* points, int n, int* rows, int nr, int* columns, int nc, int* answer) {
    if (nr == 0) return;
    int[127] reduced = {};
    int count=0;
    for (int c=0; c<nc; c++) {
        int candidate=columns[c];
        while (count>0 && score(points,n,rows[count-1],candidate) > score(points,n,rows[count-1],reduced[count-1])) count--;
        if (count<nr) reduced[count++]=candidate;
    }
    int[32] odd = {};
    int odd_count=0;
    for (int i=1; i<nr; i+=2) odd[odd_count++]=rows[i];
    maxima(points,n,&odd[0],odd_count,&reduced[0],count,answer);
    int low=0;
    for (int i=0; i<nr; i+=2) {
        int high=count-1;
        if (i+1<nr) { high=low; while (reduced[high] != answer[rows[i+1]]) high++; }
        int best=low;
        for (int j=low+1; j<=high; j++) if (score(points,n,rows[i],reduced[j]) > score(points,n,rows[i],reduced[best])) best=j;
        answer[rows[i]]=reduced[best]; low=high;
    }
}
fn long all_farthest_neighbors_convex(long* input, usz length, uchar* output, usz capacity)
        @export("all_farthest_neighbors_convex") {
    if (input == null || length < 7 || length > 129 || input[0] < 3 || input[0] > 64) return -1;
    int n=(int)input[0];
    if (length != (usz)(1+2*n)) return -1;
    Point[64] points = {};
    for (int i=0; i<n; i++) {
        long x=input[1+2*i], y=input[2+2*i];
        if (x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000) return -1;
        points[i]={x,y};
    }
    for (int i=0; i<n; i++) {
        Point a=points[i], b=points[(i+1)%n], c=points[(i+2)%n];
        if ((b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x) >= 0) return -1;
    }
    if (output == null || capacity < (usz)(8*n)) return -2;
    int[64] rows = {}, answer = {};
    int[127] columns = {};
    for (int i=0; i<n; i++) rows[i]=i;
    for (int i=0; i<2*n-1; i++) columns[i]=i;
    maxima(&points[0],n,&rows[0],n,&columns[0],2*n-1,&answer[0]);
    for (int i=0; i<n; i++) {
        ulong index=(ulong)(answer[i]%n);
        for (int byte=0; byte<8; byte++) output[8*i+byte]=(uchar)(index >> (8*byte));
    }
    return 8*n;
}
