module multinomial_naive_bayes_classifier;
import "math";

const usz MAX_INPUT_LENGTH = 360;
const usz MAX_OUTPUT_BYTES = 72;

fn long multinomial_naive_bayes_classifier(long* input, usz input_length, uint8* output,
                                           usz output_capacity)
    @export("multinomial_naive_bayes_classifier") {
    if (input == null || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1L;
    long fit_count_value = input[0];
    if (fit_count_value < 1 || fit_count_value > 2) return -1L;
    usz fit_count = (usz)fit_count_value;
    usz position = 1;
    usz feature_width = 0;
    long training_rows = 0;
    long[8] class_counts = zeroed;
    double[64] feature_sums = zeroed;
    double[8] class_totals = zeroed;
    long[16] labels = zeroed;
    long[128] training_features = zeroed;

    for (usz fit = 0; fit < fit_count; fit++) {
        if (position + 2 > input_length) return -1L;
        long rows_value = input[position++];
        long width_value = input[position++];
        if (rows_value < 1 || rows_value > 16 || width_value < 1 || width_value > 8) return -1L;
        usz rows = (usz)rows_value;
        usz width = (usz)width_value;
        if (position + rows + rows * width > input_length) return -1L;
        for (usz row = 0; row < rows; row++) {
            long label = input[position++];
            if (label < 0 || label > 7) return -1L;
            labels[row] = label;
        }
        for (usz index = 0; index < rows * width; index++) {
            long count = input[position++];
            if (count < 0 || count > 100) return -1L;
            training_features[index / width * 8 + index % width] = count;
        }

        for (usz label = 0; label < 8; label++) {
            class_counts[label] = 0;
            class_totals[label] = 0.0;
        }
        for (usz index = 0; index < 64; index++) feature_sums[index] = 0.0;
        training_rows = rows_value;
        feature_width = width;
        for (usz row = 0; row < rows; row++) {
            usz label = (usz)labels[row];
            class_counts[label]++;
            for (usz column = 0; column < width; column++) {
                double count = (double)training_features[row * 8 + column];
                feature_sums[label * 8 + column] += count;
                class_totals[label] += count;
            }
        }
    }

    if (position + 2 > input_length) return -1L;
    long prediction_count_value = input[position++];
    long prediction_width_value = input[position++];
    if (prediction_count_value < 1 || prediction_count_value > 8 ||
        prediction_width_value < 1 || prediction_width_value > 8 ||
        (usz)prediction_width_value != feature_width) return -1L;
    usz prediction_count = (usz)prediction_count_value;
    usz prediction_width = (usz)prediction_width_value;
    if (position + prediction_count * prediction_width != input_length) return -1L;
    long[64] prediction_features = zeroed;
    for (usz index = 0; index < prediction_count * prediction_width; index++) {
        long count = input[position++];
        if (count < 0 || count > 100) return -1L;
        prediction_features[index / prediction_width * 8 + index % prediction_width] = count;
    }

    long[8] predictions = zeroed;
    for (usz row = 0; row < prediction_count; row++) {
        double best_score = -1.0e300;
        double second_score = -1.0e300;
        long best_label = -1;
        for (usz label = 0; label < 8; label++) {
            if (class_counts[label] == 0) continue;
            double score = math.log((double)class_counts[label] / (double)training_rows);
            double denominator = class_totals[label] + (double)feature_width;
            for (usz column = 0; column < feature_width; column++) {
                double likelihood = (feature_sums[label * 8 + column] + 1.0) / denominator;
                score += (double)prediction_features[row * 8 + column] * math.log(likelihood);
            }
            if (score > best_score) {
                second_score = best_score;
                best_score = score;
                best_label = (long)label;
            } else if (score > second_score) {
                second_score = score;
            }
        }
        if (best_label < 0 || (second_score > -1.0e299 && best_score - second_score < 1e-8)) return -1L;
        predictions[row] = best_label;
    }

    usz output_words = prediction_count + 1;
    usz output_bytes = output_words * 8;
    if (output == null || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES) return -2L;
    long[9] fields = zeroed;
    fields[0] = prediction_count_value;
    for (usz index = 0; index < prediction_count; index++) fields[index + 1] = predictions[index];
    for (usz index = 0; index < output_words; index++) {
        ulong bits = (ulong)fields[index];
        for (usz byte = 0; byte < 8; byte++) {
            output[index * 8 + byte] = (uint8)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}
