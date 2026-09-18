# Predictive Image Coding: Double-Sided Geometric Distribution & Optimal Golomb Coding

This repository implements predictive image coding, residual error distribution fitting using a Two-Sided Geometric Distribution (TSGD), and optimal Golomb-Rice entropy coding for grayscale images (`lena.png` and `airport007.jpg`).

---

## Project Overview

In lossless/near-lossless image compression, spatial correlation between neighboring pixels is removed using linear predictive coding. The resulting prediction residual error generally follows a zero-mean, highly peaked, Laplacian-like discrete distribution: the **Two-Sided Geometric Distribution (TSGD)**. 

This project explores:
1. **Linear Pixel Prediction:** Using spatial causal contexts with weighting vector $W = [1/3, 1/3, 1/3]$.
2. **Residual Modeling:** Fitting a two-sided geometric distribution parameter $\theta$ to the empirical error.
3. **Entropy & Redundancy:** Calculating residual Shannon entropy $H(e)$ against raw image entropy.
4. **Golomb Coding:** Mapping signed residuals to non-negative integers (interleaving) and sweeping parameter $m$ to identify the rate-optimal code length $\bar{L}_{\text{opt}}$.

---

## Mathematical Formulation

### 1. Spatial Prediction Scheme
For pixel $I(r, c)$, using the causal neighborhood:
* Left: $A = I(r, c-1)$
* Top: $B = I(r-1, c)$
* Top-Left: $C = I(r-1, c-1)$

With weight vector $W = [w_1, w_2, w_3] = [1/3, 1/3, 1/3]$:
$$\hat{I}(r, c) = \text{round}(w_1 A + w_2 B + w_3 C) = \text{round}\left(\frac{A + B + C}{3}\right)$$

Residual prediction error:
$$e(r, c) = I(r, c) - \hat{I}(r, c), \quad e \in [-255, 255]$$

---

### 2. Double-Sided Geometric Distribution (TSGD) Fit
The discrete double-sided geometric distribution is defined as:
$$P(e) = \frac{1 - \theta}{1 + \theta} \cdot \theta^{\vert{}e\vert{}}, \quad e \in \mathbb{Z}, \; 0 < \theta < 1$$

The parameter $\theta$ is estimated from the sample mean absolute error (MAE):
$$\mathbb{E}[\vert{}e\vert{}] = \frac{2\theta}{1 - \theta^2} \implies \theta = \frac{\sqrt{1 + (\mathbb{E}[\vert{}e\vert{}])^2} - 1}{\mathbb{E}[\vert{}e\vert{}]}$$

---

### 3. Signed Residual Mapping (Non-negative Interleaving)
Golomb codes operate over non-negative integers $n \in \{0, 1, 2, \dots\}$. Map signed residuals $e$ via standard zig-zag interleaving:
$$n = \begin{cases} 2\vert{}e\vert{} & \text{if } e \ge 0 \\ 2\vert{}e\vert{} - 1 & \text{if } e < 0 \end{cases}$$

---

### 4. Golomb Code Construction & Length
Given parameter $m$:
1. Compute quotient $q = \lfloor n / m \rfloor$ and remainder $r = n \bmod m$.
2. **Quotient code:** Unary format ($q$ ones followed by a zero $\implies q + 1$ bits).
3. **Remainder code:** Truncated binary code:
   * Let $b = \lceil \log_2 m \rceil$.
   * If $r < 2^b - m$, encode $r$ in $(b - 1)$ bits.
   * Otherwise, encode $r + 2^b - m$ in $b$ bits.

The individual code length for residual $e \to n$:
$$L(n; m) = \lfloor n/m \rfloor + 1 + \begin{cases} b - 1 & \text{if } (n \bmod m) < 2^b - m \\ b & \text{otherwise} \end{cases}$$

Average code length:
$$\bar{L}(m) = \sum_{k} P(n = k) \cdot L(k; m)$$

Theoretical optimal parameter choice for one-sided geometric parameter $p$:
$$m \approx \left\lceil -\frac{\log(1 + p)}{\log(p)} \right\rceil$$

---

## MATLAB Implementation

### Project Structure
```text
├── README.md
├── main.m               # Top-level script to run pipeline, print tables, generate plots
├── pixelPredict.m       # Linear spatial predictor
├── fitTSGD.m            # Distribution fitting and parameter estimation
├── golombLength.m       # Calculates bit-length for mapped integers under parameter m
├── lena.png             # Test image
└── airport007.jpg       # Test image
