function c = matrixCorrelation(A, B)
% MATRIXCORRELATION Mean-centered Frobenius cosine similarity.
%
% This matches the correlation metric used in the original scripts.

A = double(A);
B = double(B);
A = A - mean(A(:));
B = B - mean(B(:));

c = sum(A(:) .* B(:)) / (norm(A(:)) * norm(B(:)) + 1e-12);
end
