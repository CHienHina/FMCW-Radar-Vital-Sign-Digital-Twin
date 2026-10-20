# FMCW Radar Vital Sign Detection & Digital Twin Simulation

This project simulates a **60 GHz FMCW Radar System** for non-contact passenger vital sign monitoring (respiration and heartbeat) inside a vehicle cabin, supporting **Driver Monitoring Systems (DMS)** and **Child Presence Detection (CPD)**. 

Built upon a **Physics-Informed Digital Twin (Software-in-the-Loop, SIL)** architecture, this repository implements the complete signal and AI processing pipeline—from millimeter-wave physical modeling and interference suppression to **Targeted Digital Beamforming** for multi-passenger spectrum separation and **Vital Spectrum Feature-Driven Machine Learning**.

## Key Features
- **60 GHz FMCW physical twin:** beat-signal radar model, fast-time range FFT, slow-time phase extraction and unwrapping (Δφ(t) = 4πx(t)/λ).
- **Domain-randomized synthetic data:** randomized noise, vehicle sway amplitude/frequency and component phases; three passenger states (Normal, Stress, Baby/CPD).
- **Spectral-feature classification:** Welch PSD peaks, energy ratio and peak quality fed to bagged decision trees; BR/HR estimation errors reported in bpm.
- **Measurement-driven window control:** the observation window extends from 10 s to 15 s when the measured heartbeat-band peak quality is low.
- **Spatial filtering exploration:** 4-RX array simulation with conventional and null-steering beamforming.

## Tools & Environment (使用工具與環境)
- **MATLAB (R2026b)**
- **Toolboxes:** Phased Array System Toolbox, Signal Processing Toolbox, Statistics and Machine Learning Toolbox

---

## Current Progress: Phase 1 - Static Target Baseline Detection (基礎測距驗證)
Generated a 60 GHz FMCW chirp waveform (Bandwidth = 4 GHz, yielding a range resolution of ΔR ≈ 3.75 cm) and applied manual Fast-Time **Range FFT** to accurately localize a static human target positioned at 0.8 m inside the cabin.

### Phase 1 Simulation Result: Range Profile

<img width="1684" height="1032" alt="Phase 1 Range FFT" src="https://github.com/user-attachments/assets/22fc08ea-361a-48c1-aa8b-0dcfa926211f" />

---

## Current Progress: Phase 2 - Dynamic Physiological Model & Phase Extraction (微動建模與相位解纏繞)
Successfully integrated the dynamic physiological chest micro-displacement model (breathing + heartbeat) with the 60 GHz FMCW radar simulation:
- Implemented a slow-time observation loop (100 fps over a 10 s window, totaling 1,000 chirps).
- Constructed a 2D **Radar Data Cube** by collecting intermediate-frequency (IF) beat signals across multiple chirps.
- Applied Fast-Time Range FFT and slow-time **Phase Unwrapping (`unwrap`)** to extract continuous physiological phase variations from the 0.8 m target range bin.

### Phase 2 Simulation Result: Phase Extraction
The following figure demonstrates the successful extraction of vital signs from the 60 GHz FMCW radar echo over a 10-second slow-time observation window:

<img width="1006" height="682" alt="Phase 2 Phase Extraction" src="https://github.com/user-attachments/assets/e6f644f2-ecf7-493f-9b30-668250ed6b80" />

**Signal Analysis:**
- **Low-Frequency Component (Respiration):** Because the 60 GHz wavelength is only λ = 5 mm, a 5 mm chest displacement induces phase shifts exceeding [-π, π]. Phase unwrapping successfully resolved these discontinuities, revealing macroscopic oscillations (≈ -13 to 13 rad) that accurately reflect the simulated 0.3 Hz breathing wave.
- **High-Frequency Ripples (Heartbeat):** The subtle micro-variations superimposed on the main respiration wave accurately capture the 1.2 Hz heartbeat displacement (amplitude ≈ 0.5 mm).
- **DSP Validation:** Validates the core Range FFT and phase unwrapping backbone, transforming raw IF beat signals into a continuous physiological phase signature.

The target appears in the 0.7875 m range bin (bin width 3.75 cm). Phase is extracted from that bin and unwrapped.
---

## Current Progress: Phase 3 - Vehicle Vibration Injection & DSP Recovery (車體顛簸雜訊注入與頻帶分離)
To simulate realistic in-cabin failure modes during driving or idling, severe low-frequency vehicle vibrations (0.1 Hz, amplitude = 20 mm) and random Gaussian white noise were injected into the Digital Twin's displacement model. The raw extracted phase was heavily corrupted, making vital signs completely indistinguishable.

We implemented dual **IIR Bandpass Filters** to isolate specific physiological frequency bands while suppressing common-mode vehicle motion:
- **Breathing Band:** 0.15 Hz - 0.5 Hz
- **Heartbeat Band:** 0.8 Hz - 2.0 Hz

### Phase 3 Results: Noise Suppression & Waveform Recovery

<img width="1386" height="1066" alt="Phase 3 DSP Filtering" src="https://github.com/user-attachments/assets/550c570e-d2c6-4fb0-9c02-5d6612fa3821" />

**Signal Analysis & DSP Performance:**
- **Raw Phase (Top):** Heavily distorted by large-amplitude vehicle swaying (± 50 rad) and high-frequency random noise; micro-vital signs are completely submerged.
- **Respiration Recovery (Middle):** Applying the 0.15 - 0.5 Hz bandpass filter eliminates the 0.1 Hz vehicle sway, recovering a clean 0.3 Hz breathing waveform.
- **Heartbeat Recovery (Bottom):** A subsequent 0.8 - 2.0 Hz bandpass filter isolates the much weaker 1.2 Hz heartbeat signal (± 2 rad) from both the dominant respiration wave and environmental noise.
- **Conclusion:** Demonstrates the effectiveness of the front-end DSP pipeline in separating micro-vital signs from mechanical interference, providing clean time-domain inputs for subsequent spectral feature extraction.

---

## Current Progress: Phase 4 - AI Processing Chain, Vital Spectrum Features & Closed-Loop Control (AI 處理鏈、生命頻譜特徵擷取與閉環控制)
In this phase, we expanded the traditional DSP flow into an integrated **AI Processing Chain**, transitioning from raw signal extraction to **Intelligent State Recognition** and **Closed-Loop System Control** for Driver Health Monitoring and Child Presence Detection (CPD).

### 1. Sim2Real Synthetic Data Generation & Closed-Loop Feedback
To overcome the scarcity and ethical risks of collecting extreme real-world data (e.g., leaving an infant in a vibrating vehicle), the Digital Twin engine generated **150 synthetic samples** across three passenger states:
- **Normal:** Standard adult resting respiration (0.25 Hz, 5 mm) and heart rate (1.2 Hz, 0.5 mm).
- **Stress:** Elevated vital signs (0.5 Hz breathing, 1.8 Hz heartbeat) simulating driver fatigue or acute physiological stress.
- **Baby (CPD):** High-frequency (0.4 Hz breathing, 2.2 Hz heartbeat) but **extremely low-amplitude displacements** (1.5 mm breathing, 0.2 mm heartbeat) representing a left-behind infant.

**Closed-Loop Feedback Mechanism:** The system continuously evaluates background noise and signal uncertainty. When severe environmental noise is detected (`noise_level > 0.0012`), the system triggers a closed-loop response, **dynamically extending the observation window from 10 seconds to 15 seconds** to accumulate sufficient slow-time energy before feature extraction.

### 2. Vital Spectrum Feature Extraction & ML Classification Results
Rather than training AI models solely on spatial point clouds, our AI processing chain computes **Welch's Power Spectral Density (PSD)** on the filtered phase signals to extract **Vital Spectrum Features** (dominant respiration/heartbeat spectral peaks and energy distribution). These features are fed into a lightweight **Random Forest Classifier**.

**Feature Space Distribution & Classification Confusion Matrix:**

<img width="2000" height="840" alt="image" src="https://github.com/user-attachments/assets/3c4553bb-db75-4eaf-b0f2-9b95f5d7d5de" />


### Evaluation
5-fold cross-validation on 150 synthetic samples, repeated over 10 random seeds (mean ± std). Two factors are compared: the Welch setting (MATLAB default vs. full-length window with a fine frequency grid) and the feature set (frequencies only vs. frequencies + energy ratio + peak quality).

| Welch | Features | Normal | Stress | Baby (CPD) |
|---|---|---|---|---|
| default | frequencies | 95.6 ± 2.8% | 98.8 ± 1.8% | 58.8 ± 8.2% |
| default | + energy | 95.6 ± 2.6% | 87.1 ± 6.5% | 80.5 ± 4.5% |
| fine | frequencies | 96.3 ± 2.1% | 87.4 ± 4.9% | 84.6 ± 5.1% |
| fine | + energy | 98.6 ± 1.3% | 95.3 ± 2.0% | 95.9 ± 1.8% |

### BR/HR estimation (fine Welch, mean absolute error in bpm / share within ±5%)
| Class | BR | HR |
|---|---|---|
| Normal | 0.69 / 67% | 0.37 / 100% |
| Stress | 0.63 / 98% | 0.30 / 100% |
| Baby (CPD) | 2.04 / 86% | 10.16 / 82% |

### Observations
- With the default `pwelch` settings the frequency grid is about 0.39 Hz for 10 s windows (0.195 Hz for 15 s), so the breathing rates of the three states fall into the same bin. A finer grid and two energy-based features raise the Baby class from 58.8% to 95.9% in this simulation.
- The first single-run result (47.8%) is within the spread of the default setting (58.8 ± 8.2%).
- Infant heart rate remains the weakest estimate (heartbeat 0.2 mm vs. 0.5–1.5 mm injected noise).
- The infant is low-amplitude by construction in the generator, so energy features help here; this must be validated on real data.
- The window extension is triggered by a quality index measured from the signal (peak-to-median power ratio in the heartbeat band over the first 10 s, threshold 12).
- **The Value of the Digital Twin:** Instead of discovering this fatal CPD blind spot during real-vehicle deployment, our SIL Digital Twin safely exposed the physical boundary of unsteered 1D frequency filtering, directly motivating our **Phase 5 spatial beamforming architecture**.

---

## Current Progress: Phase 5 - Targeted Beamforming for Multi-Passenger Vital Spectrum Separation (空間波束指向與多乘員生命頻譜剝離)
In a realistic multi-passenger cabin, vital signals from multiple occupants (e.g., an adult driver and a rear-seat infant) and severe vehicle vibrations overlap simultaneously in both time and frequency domains. Furthermore, computationally heavy super-resolution estimators (such as DR-MUSIC) are prohibitive for real-time execution on automotive SoCs.

To resolve the Phase 4 CPD failure and decouple multiple passengers within SoC constraints, we implemented **Targeted Digital Beamforming** tightly coupled with our **Vital Spectrum AI Processing Chain**:
1. **Seat-Specific Spatial Beam Steering:** Utilizing a standard 4-RX automotive antenna array (λ/2 spacing), the system steers a spatial beam toward the specific seat coordinate of the infant (+15°) while placing a spatial null toward the strong interfering adult driver (-20°).
2. **Multi-Passenger Vital Spectrum Decoupling:** By extracting the slow-time physiological phase exclusively from the steered +15° spatial bin, the infant's weak micro-vital spectrum is cleanly separated from the adult's respiration clutter and fed into the PSD feature extractor.


## Phase 5 - Spatial Filtering Exploration
Two occupants share one range bin (infant at +15°, adult at -20°); a 4-RX array (λ/2 spacing) receives phase-modulated returns with per-element complex noise. Seat angles are assumed known within 2°. Phase is extracted with `unwrap(angle(.))` and band-pass filtered, over 30 noise realizations.

<img width="2352" height="1176" alt="image" src="https://github.com/user-attachments/assets/9df611bf-ad45-4d08-a273-06ce96920679" />


| Method | Phase RMSE (rad) | BR within ±5% | HR within ±5% |
|---|---|---|---|
| single antenna | 8.11 | 0% | 0% |
| conventional beamforming | 1.67 | 90% | 53% |
| null toward adult | 1.28 | 93% | 93% |

- A single antenna follows the stronger adult occupant.
- Conventional beamforming moves the dominant peak to the infant's breathing but leaves adult leakage; nulling toward the adult reduces it, at the cost of needing the adult's direction.
- Echo amplitudes, noise level and the 2° angle error are assumptions; this is an illustration, not a performance claim.

**Engineering & Physical Insights:**
- **1A. Before Beamforming (Top-Left):** Without spatial steering, the received phase (grey) is heavily corrupted by cross-talk from the adult driver (-20°, 5 mm breathing) and vehicle vibrations, failing to track the infant's 1.5 mm ground-truth waveform (red).
- **1B. After Steering Beam to +15° Seat (Bottom-Left):** Following a brief 0 - 2 s IIR bandpass filter transient response, the spatially steered signal (blue) suppresses off-axis interference and accurately reconstructs the infant's true physiological phase (red), including both the 0.4 Hz breathing wave and 2.2 Hz heartbeat ripples.
- **2. Vital Spectrum Separation for AI (Right):** 
  - **Before Steering (Grey Dashed Line):** The normalized spectrum is hijacked by the adult driver's strong breathing component near 0.25 Hz, completely masking the infant's signature and explaining the Phase 4 ML misclassifications.
  - **After Steering to +15° (Blue Solid Line):** The adult interference at 0.25 Hz is eliminated. The extracted vital spectrum clearly reveals the infant's true respiration peak at **0.40 Hz** and heartbeat peak at **2.20 Hz**, providing clean, high-dimensional spectral features for the downstream AI classifier.

---

## Candidate Directions (not yet decided) & Future Roadmap (現狀與計畫目標差距及未來展望)
To bridge this SIL prototype with the final 2-year NYCU × Whetron industrial project goals (WP1–WP4), our upcoming development focuses on four key upgrades:

1. **Multi-Seat Automated Beam Scanning:** Expand fixed-angle steering to automated 2D Range-Angle FFT + CFAR detection, dynamically steering multiple digital beams to simultaneously isolate and monitor ≥ 2 passengers across all cabin seats.
2. **Enhanced AI Noise Suppression with Full Spectral Features:** Move beyond simple spectral peak-picking by feeding full **vital spectrum envelopes, spectral entropy, variance, and time-frequency representations** into lightweight neural networks (1D-CNN / MLP) and harmonic comb filters, enabling the AI model to directly learn and suppress residual motion artifacts and breathing harmonics on edge SoCs.
3. **Multi-Sensor Fusion (Camera + Radar + IMU) for 3–5 Min Early Warning:** Integrate cabin optical camera cues (head pose, eyelid closure PERCLOS) with 60 GHz radar physiological trends (Heart Rate Variability - HRV and respiratory rhythm shifts) alongside onboard IMU vibration compensation. This multi-modal AI fusion aims to achieve **3 to 5 minutes of early warning** prior to severe driver drowsiness or acute cardiopulmonary events.
4. **Real-Vehicle HIL & Hybrid Twin Calibration:** Connect this unified MATLAB processing pipeline to Whetron's 60 GHz radar hardware I/Q data cube and ECG ground truth (< 10 ms timestamp alignment) to calibrate the Level 2/3 cabin multipath digital twin.

## Limitations
- Simulation only; no real radar data.
- Noise is injected in the phase domain and assumes ideal phase unwrapping (about 1.3–3.8 rad rms per sample for 0.5–1.5 mm noise would break unwrapping on a real chain).
- Single-frequency vehicle sway; no body motion, breathing harmonics, or multipath.
- Infant parameters (rates, amplitudes) are assumed; compute cost on target hardware not measured.
