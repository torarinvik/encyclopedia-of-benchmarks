#include <stddef.h>
#include <stdint.h>
static int is_prime(int64_t n) { if (n < 2) return 0; for (int64_t d=2; d*d<=n; ++d) if (n%d==0) return 0; return 1; }
static int64_t modpow(int64_t b, int64_t e, int64_t p) { int64_t r=1%p; b%=p; while(e){if(e&1)r=r*b%p;b=b*b%p;e>>=1;}return r; }
int64_t diffie_hellman(const int64_t *v, size_t n) {
 if (!v || n!=4) return -1; int64_t g=v[0], a=v[1], b=v[2], p=v[3];
 if(p<2||p>6700417||!is_prime(p)||g<1||g>=p||a<1||a>=p||b<1||b>=p)return -1;
 return modpow(modpow(g,a,p),b,p);
}
