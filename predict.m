% Process both images
images = {'lena.png', 'airport007.jpg'};
% Prediction filter: w1 (up), w2 (up-left), w3 (left) all equal to 1/3
f = [1/3 1/3 0; 
     1/3  0  0; 
      0   0  0];
for i = 1:length(images)
    im = imread(images{i});
    if size(im, 3) == 3
        im = rgb2gray(im);
    end
    % Generate predicted image and residual
    im_pred = imfilter(double(im), f);
    im_pred(1,:) = im(1,:); im_pred(:,1) = im(:,1); % Handle borders
    res = double(im) - double(im_pred);
    % Compute required metrics
    res_flat = res(:);
    variance = var(res_flat);
    mu = mean(abs(res_flat));
    % Estimate distribution parameter p
    % sigma^2 = 2p / (1-p)^2 => p^2 - (2 + 2/sigma^2)p + 1 = 0
    c = 2 + 2/variance;
    p = (c - sqrt(c^2 - 4)) / 2; % Select root < 1
    % Calculate exact Residual Entropy (requires histogram)
    [counts, edges] = histcounts(res_flat, 'BinMethod', 'integers');
    probs = counts / sum(counts);
    probs(probs == 0) = []; % Remove zero probabilities
    H_res = -sum(probs .* log2(probs));
    % Plotting (Part A)
    figure;
    subplot(1,2,1); imshow(uint8(im)); title(['Original: ', images{i}]);
    subplot(1,2,2); histogram(res_flat, 'BinMethod', 'integers', 'Normalization', 'probability');
    title(sprintf('Residual Dist\\nH(res)=%.2f', H_res));
    xlim([-100 100]);
    % Print values for the report
    fprintf('\n--- Image: %s ---\n', images{i});
    fprintf('Variance (sigma^2): %.2f\n', variance);
    fprintf('Fitted p-value: %.4f\n', p);
    fprintf('Mean Absolute Error (mu): %.2f\n', mu);
    fprintf('Theoretical Optimal m: %.2f\n', log(2) * mu);
    fprintf('Residual Entropy H(res): %.4f bits\n', H_res);
    % Empirical testing for Golomb m (Part B)
    m_test = floor(log(2)*mu)-1 : ceil(log(2)*mu)+1; % Test surrounding integers
    % Map residuals to non-negative integers N for Golomb coding
    % N = 2x if x >= 0, N = 2|x|-1 if x < 0
    N = zeros(size(res_flat));
    N(res_flat >= 0) = 2 * res_flat(res_flat >= 0);
    N(res_flat < 0) = 2 * abs(res_flat(res_flat < 0)) - 1;
    fprintf('Golomb Coding Lengths:\n');
    for m = m_test
        if m < 1; continue; end
        q = floor(N / m);
        % Code length = unary part (q+1) + binary part (floor(log2(m)) or ceil(log2(m)))
        % Simplified average estimation for report purposes:
        c_len = q + 1 + floor(log2(m)); 
        avg_len = mean(c_len);
        fprintf('  m = %d -> Avg Length = %.4f bits/pixel\n', m, avg_len);
    end
end
