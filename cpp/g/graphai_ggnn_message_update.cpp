/* Clean-room bounded one-step gated graph-message update. */
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t graphai_ggnn_message_update(
    const double* input, std::size_t length, double* output,
    std::size_t capacity) noexcept {
    constexpr std::size_t N = 8, M = 24, D = 4;
    constexpr std::size_t MAX_PARSEABLE = 453;
    if (!input || length < 3 || length > MAX_PARSEABLE) return -1;
    for (std::size_t q = 0; q < length; ++q) if (!std::isfinite(input[q])) return -1;
    const double nv = input[0], mv = input[1], dv = input[2];
    if (std::trunc(nv) != nv || std::trunc(mv) != mv || std::trunc(dv) != dv ||
        nv < 1 || nv > N || mv < 0 || mv > M || dv < 1 || dv > D) return -1;
    const auto n = static_cast<std::size_t>(nv);
    const auto m = static_cast<std::size_t>(mv);
    const auto d = static_cast<std::size_t>(dv);
    if (length != 4 + n + m + n*d + 6*n*n) return -1;
    const std::size_t row_at = 3, col_at = row_at+n+1, h_at = col_at+m;
    const std::size_t wz_at = h_at+n*d, wr_at = wz_at+n*n;
    const std::size_t wc_at = wr_at+n*n, uz_at = wc_at+n*n;
    const std::size_t ur_at = uz_at+n*n, uc_at = ur_at+n*n;
    if (input[row_at] != 0 || input[col_at-1] != static_cast<double>(m)) return -1;
    std::size_t row[N+1]{}, col[M]{};
    for (std::size_t i=0; i<=n; ++i) {
        const double x=input[row_at+i];
        if (std::trunc(x)!=x || x<0 || x>static_cast<double>(m)) return -1;
        row[i]=static_cast<std::size_t>(x);
        if (i && row[i]<row[i-1]) return -1;
    }
    for (std::size_t e=0; e<m; ++e) {
        const double x=input[col_at+e];
        if (std::trunc(x)!=x || x<0 || x>=static_cast<double>(n)) return -1;
        col[e]=static_cast<std::size_t>(x);
    }
    for (std::size_t q=h_at; q<wz_at; ++q) if (input[q]<-1 || input[q]>1) return -1;
    for (std::size_t q=wz_at; q<length; ++q) if (input[q]<-0.25 || input[q]>0.25) return -1;
    const auto required=n*d;
    if (!output || capacity<required) return -2;
    double aggregate[N*D]{}, update[N*D]{}, reset[N*D]{}, candidate[N*D]{}, staged[N*D]{};
    for (std::size_t v=0; v<n; ++v) for (std::size_t e=row[v]; e<row[v+1]; ++e)
        for (std::size_t f=0; f<d; ++f) aggregate[v*d+f]+=input[h_at+col[e]*d+f];
    for (std::size_t v=0; v<n; ++v) for (std::size_t f=0; f<d; ++f) {
        double z=0, r=0, wz=0, wr=0;
        for (std::size_t k=0; k<n; ++k) {
            const auto a=v*n+k, b=k*d+f;
            wz+=input[wz_at+a]*aggregate[b]; wr+=input[wr_at+a]*aggregate[b];
            z+=input[uz_at+a]*input[h_at+b]; r+=input[ur_at+a]*input[h_at+b];
        }
        const auto at=v*d+f;
        update[at]=1.0/(1.0+std::exp(-(wz+z)));
        reset[at]=1.0/(1.0+std::exp(-(wr+r)));
    }
    for (std::size_t v=0; v<n; ++v) for (std::size_t f=0; f<d; ++f) {
        double from_graph=0, from_state=0;
        for (std::size_t k=0; k<n; ++k) {
            const auto a=v*n+k, b=k*d+f;
            from_graph+=input[wc_at+a]*aggregate[b];
            from_state+=input[uc_at+a]*(reset[b]*input[h_at+b]);
        }
        const auto at=v*d+f;
        candidate[at]=std::tanh(from_graph+from_state);
        staged[at]=(1.0-update[at])*input[h_at+at]+update[at]*candidate[at];
    }
    for (std::size_t q=0; q<required; ++q) output[q]=staged[q];
    return static_cast<std::int64_t>(required);
}
