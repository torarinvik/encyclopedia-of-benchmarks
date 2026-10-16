module density;
const long MAX_NODES=100000;
const double INVALID_RESULT=-1.0e300;

fn double density(long* values, usz length) @export("density") {
    if (values==null || length!=3) return INVALID_RESULT;
    long nodes=values[0]; long edges=values[1]; long directed=values[2];
    if (nodes<2 || nodes>MAX_NODES || (directed!=0 && directed!=1)) return INVALID_RESULT;
    long max_edges=nodes*(nodes-1);
    if (directed==0) max_edges/=2;
    if (edges<0 || edges>max_edges) return INVALID_RESULT;
    double factor=directed==1 ? 1.0 : 2.0;
    return (factor*(double)edges)/((double)nodes*(double)(nodes-1));
}
