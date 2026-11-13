module romberg_integration;

extern fn double exp(double value);
extern fn double cos(double value);

const usz MAX_INPUT_LENGTH = 5;

fn bool integer_field(double x, long lo, long hi, long* decoded) {
    if (!(x == x) || x < (double)lo || x > (double)hi || (double)(long)x != x) return false;
    *decoded = (long)x;
    return true;
}

fn double integrand(long id, double x) {
    if (id == 0) return exp(x);
    if (id == 1) return x*x*x*x*x;
    if (id == 2) return 1.0/(1.0+x*x);
    return cos(x);
}

fn double romberg(long id, double a, double b, long levels) {
    if (a == b) return 0.0;
    double[9] previous = {0};
    previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5;
    for (long level=1; level<=levels; level++) {
        long interval_count = 1L << level;
        double spacing = (b-a)/(double)interval_count;
        double added = 0.0;
        for (long index=1; index<interval_count; index+=2)
            added += integrand(id,a+(double)index*spacing);
        double[9] current = {0};
        current[0] = previous[0]*0.5+spacing*added;
        double factor = 4.0;
        for (long order=1; order<=level; order++) {
            current[order] = current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0);
            factor *= 4.0;
        }
        for (long order=0; order<=level; order++) previous[order]=current[order];
    }
    return previous[levels];
}

fn long romberg_integration(double* input, usz input_length,
                            double* output, usz output_capacity)
    @export("romberg_integration") {
    if (input == null || input_length != 4 || input_length > MAX_INPUT_LENGTH) return -1L;
    long id; long a_micro; long b_micro; long levels;
    if (!integer_field(input[0],0,3,&id) ||
        !integer_field(input[1],-1000000,1000000,&a_micro) ||
        !integer_field(input[2],-1000000,1000000,&b_micro) ||
        !integer_field(input[3],3,8,&levels) || a_micro>b_micro) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    double result = romberg(id,(double)a_micro/1000000.0,(double)b_micro/1000000.0,levels);
    if (!(result == result) || result > 1e308 || result < -1e308) return -1L;
    output[0]=result;
    return 1L;
}
