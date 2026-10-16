# Naive Bayes text classification

This benchmark follows the pinned Python multinomial Naive Bayes classifier: lowercase text tokenization, class document priors, add-alpha token likelihoods, log-space scoring, and a normalized posterior. To keep the byte-array contract bounded and portable, each training document and query contains at most one ASCII token of at most eight characters (`a-z`, `A-Z`, digits, apostrophe); labels are restricted to `ham` and `spam`, and both classes must appear in training. Empty texts tokenize to no tokens.

Input is `[document_count, alpha_milli, (label, token_length, ASCII bytes)*, query_length, query_bytes...]`; label 0 means `ham`, label 1 means `spam`. Document count is 2–6, alpha is 0.001–10, and each token is at most eight bytes. Output is `[P(ham), P(spam)]` as two little-endian binary64 values. Invalid inputs return -1. Runtime oracle: `naive_bayes_text_classification_oracle.py`.
