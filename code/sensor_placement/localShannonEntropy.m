function H = localShannonEntropy(values, numBins)
% LOCALSHANNONENTROPY Shannon entropy of a one-dimensional sample.
%
% This preserves the original repository behavior: each pixel receives its
% own histogram range from its local min/max values across simulations.

values = values(:);
values = values(isfinite(values));

if isempty(values)
    H = 0;
    return;
end

vMin = min(values);
vMax = max(values);
if vMax - vMin < eps(max(1, abs(vMax)))
    H = 0;
    return;
end

edges = linspace(vMin, vMax, numBins + 1);
counts = histcounts(values, edges);
if ~any(counts)
    H = 0;
    return;
end

p = counts / sum(counts);
p = p(p > 0);
H = -sum(p .* log2(p));
end
