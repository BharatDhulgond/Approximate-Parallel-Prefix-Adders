# Approximate Parallel Prefix Adders (AxPPA)

**Configurable-accuracy parallel prefix adders in Verilog — trading arithmetic precision for area, delay, and power in error-resilient hardware accelerators.**

[![Vivado](https://img.shields.io/badge/Tool-Xilinx%20Vivado-blue)]()
[![Target](https://img.shields.io/badge/Target-Artix--7%20(xc7a35t)-informational)]()
[![Language](https://img.shields.io/badge/HDL-Verilog-orange)]()

---

## Overview

Parallel Prefix Adders (PPAs) — Brent-Kung, Kogge-Stone, Ladner-Fischer, and Sklansky — are the fastest known adder topologies, using logarithmic-depth carry trees to minimize critical-path delay. This comes at a fixed cost: every bit position, regardless of significance, receives full exact carry-propagate logic.

**AxPPA** challenges that assumption. In error-tolerant workloads (ML inference, DSP, image/video processing), errors in the Least Significant Bits (LSBs) contribute negligibly to overall output magnitude. This project introduces an **Approximate Prefix Operator (AxPO)** that replaces exact carry logic in the `K` least significant bits with a direct wire passthrough — eliminating an entire region of the prefix tree — while preserving an exact prefix computation for the remaining `W−K` most significant bits.

The result: adders that are smaller, faster, and lower-power than their exact counterparts, with accuracy loss that is bounded, configurable, and quantifiable via standard error metrics.

This work is a hardware implementation and design-space exploration inspired by the IEEE TVLSI paper *"AxPPA: Approximate Parallel Prefix Adders"* (Rosa et al., 2023).

---

## Key Highlights

| Metric | Result |
|---|---|
| Architectures implemented | Brent-Kung, Kogge-Stone, Ladner-Fischer, Sklansky (exact + approximate) |
| Peak LUT savings | **up to 72%** (Ladner-Fischer, K = W) |
| Peak critical-path delay reduction | **up to 48%** (Kogge-Stone, K = W) |
| Accuracy retained | **MRED < 4%** for K ≤ W/4 |
| Configurability | Fully parameterized word width (`W`) and approximation depth (`K`) |
| Verification | Functional + statistical error-metric testbenches (MAE, MRED, WCE) |

---

## Architecture

### Standard Prefix Computation

Every PPA is built from three stages — preprocessing, prefix computation, and postprocessing — around the associative Prefix Operator (PO):

```
P = pᵢ · pᵢ₊₁
G = (gᵢ · pᵢ₊₁) + gᵢ₊₁
```

Prefix trees differ in how POs are arranged (fan-out, tree depth, node count), giving each architecture a distinct area/delay signature.

### The AxPO Approximation

For a configurable window of `K` LSBs, the exact PO is replaced with a wire-only AxPO:

```
P ≈ pᵢ₊₁
G ≈ gᵢ₊₁
```

This removes the prefix tree entirely from the approximate region — no AND/OR gate logic, only routing — while the remaining `W−K` MSBs retain a full exact prefix tree, seeded by the carry emerging from the approximate region.

```
 ┌─────────────── W bits ───────────────┐
 │   Exact Prefix Tree (W−K bits, MSB)   │  AxPO Region (K bits, LSB)  │
 │        full G/P propagation           │      wire passthrough      │
 └────────────────────────────────────────────────────────────────────┘
```

`K = 0` recovers the exact adder. `K = W` yields the maximally approximate, minimum-area adder.

### Error Evaluation

Approximation quality is profiled using standard error-tolerant computing metrics over pseudo-random test vectors:

**Mean Relative Error Distance (MRED)**

$$\text{MRED} = \frac{1}{n}\sum_{i=1}^{n}\frac{|measured_i - actual_i|}{actual_i}$$

Mean Absolute Error (MAE) and Worst-Case Error (WCE) are also extracted per architecture, per `K`.

---

## Repository Structure

```text
.
├── rtl/                     # Verilog source — all adder architectures
│   ├── PO.v                 # Generic exact Prefix Operator (building block)
│   ├── W_PPA.v               # Generic exact W-bit PPA (built from PO)
│   ├── Ax_WPPA.v              # Generic approximate W-bit AxPPA
│   ├── axppa_bk.v            # Approximate Brent-Kung adder
│   ├── ks_axppa.v             # Approximate Kogge-Stone adder
│   ├── lf_axppa.v             # Approximate Ladner-Fischer adder
│   ├── lf_ppa_exact.v          # Exact Ladner-Fischer adder (golden model)
│   ├── lf_wrapper.v            # Ladner-Fischer top-level wrapper
│   └── sk_axppa.v             # Approximate Sklansky adder (in progress)
├── tb/                      # Testbenches — functional + MRED/MAE/WCE profiling
├── docs/                    # Presentation slides, synthesis reports, result graphs
└── README.md
```

---

## Results & Synthesis

*All designs synthesized in Xilinx Vivado, targeting Artix-7 (`xc7a35ticpg236-1L`).*

| Architecture | Prefix Tree Characteristics | Approximation Impact |
|---|---|---|
| **Kogge-Stone** | Maximum node count, minimum depth, high fan-out | Largest critical-path delay reduction under approximation (~48%) |
| **Ladner-Fischer** | Balanced depth/fan-out | Best overall LUT savings (~72%) with consistently strong delay scaling |
| **Brent-Kung** | Minimum node count, regular layout | Smallest baseline area; moderate marginal savings from approximation |
| **Sklansky** | High fan-out, shallow depth | Moderate LUT/delay improvement; fan-out limits gains |

**Design-space trends observed:**
- LUT utilization decreases near-linearly with `K` for all architectures, with diminishing returns once the approximate region fully absorbs the LSB tree.
- Critical-path delay drops sharply for small-to-moderate `K`, then plateaus once the exact MSB region dominates the path.
- MRED grows slowly for `K ≤ W/4` (low-significance bits only) and accelerates sharply beyond `K ≈ W/2`, as carry-chain loss propagates into higher-magnitude bits.

![MRED Graph](https://github.com/BharatDhulgond/Approximate-Parallel-Prefix-Adders/blob/main/docs/mred_graph.png?raw=true)

---

## How to Use

### Prerequisites
- Xilinx Vivado 2022.x or later
- Target part used in this project: `xc7a35ticpg236-1L` (Artix-7)

### 1. Clone the Repository
```bash
git clone https://github.com/BharatDhulgond/Approximate-Parallel-Prefix-Adders.git
cd Approximate-Parallel-Prefix-Adders
```

### 2. Create a Vivado RTL Project
1. **File → Project → New → RTL Project**
2. Add all files under `/rtl` as **Design Sources**
3. Add all files under `/tb` as **Simulation Sources**
4. Set **Default Part** to `xc7a35ticpg236-1L` (or your target board)

### 3. Module Reference

| Architecture | File | Top Module | Parameters | Ports |
|---|---|---|---|---|
| Brent-Kung (approx.) | `axppa_bk.v` | `axppa_bk` | `W`, `K` | `A, B, cin → S, cout` |
| Kogge-Stone (approx.) | `ks_axppa.v` | `kogge_stone_axppa` | `WIDTH`, `K` | `a, b, cin → sum, cout` |
| Ladner-Fischer (approx.) | `lf_axppa.v` | see file | `WIDTH`, `K` | `a, b, cin → sum, cout` |
| Ladner-Fischer (exact, golden model) | `lf_ppa_exact.v`, `lf_wrapper.v` | `lf_ppa_top` | `WIDTH` | `a, b, cin → sum, cout` |
| Generic exact PPA | `W_PPA.v` | `W_PPA` | `N` | `a, b, cin → fullsum` |
| Generic Prefix Operator | `PO.v` | `PO` | — | `p1, p2, g1, g2 → newp, newg` |

> **Note:** parameter/port naming (`W` vs `WIDTH`, `A/B/S` vs `a/b/sum`) is not yet unified across architectures. Standardize the interface if integrating multiple adders under one top-level testbench.

### 4. Instantiate an Adder

Example — 16-bit approximate Kogge-Stone adder with 4 approximated LSBs:

```verilog
kogge_stone_axppa #(
    .WIDTH(16),
    .K(4)
) u_adder (
    .a    (a),
    .b    (b),
    .cin  (cin),
    .sum  (sum),
    .cout (cout)
);
```

`K = 0` → fully exact adder. `K = WIDTH` → maximally approximate adder.

### 5. Functional & Error-Metric Verification
1. Open the corresponding testbench in `/tb`.
2. **Flow Navigator → Run Simulation → Run Behavioral Simulation**.
3. Testbenches compare approximate output against a golden exact-adder reference over pseudo-random and edge-case vectors, reporting **MAE**, **MRED**, and **WCE**.

### 6. Area / Timing / Power Characterization
1. **Flow Navigator → Run Synthesis** (and **Run Implementation** for post-route results).
2. Extract **LUT utilization** (Utilization Report), **critical-path delay** (Timing Summary), and **on-chip power** (Power Report).
3. Sweep `K` from `0` to `WIDTH` and re-synthesize to reproduce area/delay/power vs. `K` curves in `/docs`.

---

## Reference

> M. M. A. da Rosa, G. Paim, P. Ü. L. da Costa, E. A. C. da Costa, R. I. Soares, and S. Bampi, **"AxPPA: Approximate Parallel Prefix Adders,"** *IEEE Transactions on Very Large Scale Integration (VLSI) Systems*, vol. 31, no. 1, pp. 17–28, Jan. 2023. [doi:10.1109/TVLSI.2022.3218021](https://doi.org/10.1109/TVLSI.2022.3218021)

---

## Authors

Bharat Kumar · Vinay P Ramesh · R Vaikunth · Surya Sumeet Singh · Pravin Kumar V · Shudharshan A · Harshit Krishna R
