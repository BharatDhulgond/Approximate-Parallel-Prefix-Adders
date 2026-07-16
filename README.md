
# Approximate Parallel Prefix Adders (AxPPA) in Verilog

## Overview

Parallel Prefix Adders (PPAs) — Brent-Kung, Kogge-Stone, Ladner-Fischer, and Sklansky — are the fastest known adder topologies, using logarithmic-depth carry trees to minimize critical-path delay. This comes at a fixed cost: every bit position, regardless of significance, receives full exact carry-propagate logic.

AxPPA challenges that assumption. In error-tolerant workloads (ML inference, DSP, image/video processing), errors in the Least Significant Bits (LSBs) contribute negligibly to overall output magnitude. This project introduces an Approximate Prefix Operator (AxPO) that replaces exact carry logic in the K least significant bits with a direct wire passthrough — eliminating an entire region of the prefix tree — while preserving an exact prefix computation for the remaining W−K most significant bits.

The result: adders that are smaller, faster, and lower-power than their exact counterparts, with accuracy loss that is bounded, configurable, and quantifiable via standard error metrics.

This work is a hardware implementation and design-space exploration inspired by the IEEE TVLSI paper "AxPPA: Approximate Parallel Prefix Adders" (Rosa et al., 2023).
## Key Highlights

* **Architectures Implemented:** Brent-Kung, Kogge-Stone, Ladner-Fischer, and Sklansky parallel prefix trees.
* **Configurable Approximation:** Fully parameterized Verilog modules allowing configurable word widths ($W$) and approximation levels ($K$ LSBs).
* **Hardware Efficiency:** Achieved up to **72% LUT savings** and a **48% reduction in critical-path delay** compared to exact parallel prefix adders.
* **Error Resilience:** Sustained a Mean Relative Error Distance (MRED) of **<4%**, proving the viability of AxPPA for hardware accelerators.

## The Approximation Technique

Traditional Parallel Prefix Adders (PPAs) optimize carry generation (G) and propagation (P) using a logarithmic tree of Prefix Operators.

In this AxPPA architecture, the prefix logic for a configurable number of $K$ LSBs is stripped away. Instead of computing exact carries, the lower bits utilize an **Approximate Prefix Operator (AxPO)**, which acts as a direct wire passthrough. The exact prefix tree is only instantiated for the remaining Most Significant Bits (MSBs), drastically shortening the critical path and minimizing gate count.

### Error Evaluation (MRED)

Accuracy degradation was profiled using Mean Relative Error Distance (MRED) across pseudo-random test vectors:

$$\text{MRED} = \frac{1}{n}\sum_{i=1}^{n}\frac{\vert{}measured_{i}-actual_{i}\vert{}}{actual_{i}}$$

## Repository Structure

```text
├── rtl/                   # Verilog source files for all adder architectures
│   ├── PO.v               # Standard Prefix Operator
│   ├── axppa_bk.v         # Approximate Brent-Kung Adder
│   ├── ks_axppa.v         # Approximate Kogge-Stone Adder
│   ├── lf_axppa.v         # Approximate Ladner-Fischer Adder
│   ├── sk_axppa.v         # Approximate Sklansky Adder (Add when ready)
│   └── lf_ppa_exact.v     # Exact Ladner-Fischer (Golden Model)
├── tb/                    # Testbenches for functional verification and MRED profiling
├── docs/                  # Project presentation, synthesis reports, and data graphs
└── README.md              

```

## Results & Synthesis

*All designs were synthesized using Xilinx Vivado targeting the Artix-7 FPGA architecture.*

| Architecture | Characteristics & Impact |
| --- | --- |
| **Kogge-Stone** | Maximum prefix nodes; yielded the highest critical path delay reduction when approximated. |
| **Ladner-Fischer** | Balanced prefix tree; provided the optimal trade-off with up to 60-72% LUT utilization savings. |
| **Brent-Kung** | Minimal baseline nodes; provided moderate delay and area savings. |
| **Sklansky** | High fan-out nodes; demonstrated moderate LUT and delay improvements. |

![MRED Graph](https://github.com/BharatDhulgond/Approximate-Parallel-Prefix-Adders/blob/main/docs/mred_graph.png?raw=true)

## How to Use

To simulate or synthesize the designs in Vivado:

1. Clone the repository to your local machine.
2. Create a new RTL project in Vivado and add the files from the `/rtl` directory as design sources.
3. Instantiate the desired adder in your top-level module, defining the parameters `WIDTH` (total bits) and `K` (approximated bits).
4. Run the provided testbenches in the `/tb` folder to verify functional approximation and extract error metrics.

## References

This hardware implementation is inspired by the methodologies discussed in the IEEE Transactions on VLSI Systems paper:

> [*AxPPA: Approximate Parallel Prefix Adders* (Rosa et al., 2023)](https://doi.org/10.1109/TVLSI.2022.3218021)
