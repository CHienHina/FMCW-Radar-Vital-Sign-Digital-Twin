# FMCW Radar Vital Sign Detection & Digital Twin Simulation

This project simulates a **60 GHz FMCW Radar System** for non-contact passenger vital sign monitoring (respiration and heartbeat) inside a vehicle cabin, supporting **Driver Monitoring Systems (DMS)** and **Child Presence Detection (CPD)**. 

Built upon a **Physics-Informed Digital Twin (Software-in-the-Loop, SIL)** architecture, this repository implements the complete signal and AI processing pipeline—from millimeter-wave physical modeling and interference suppression to **Targeted Digital Beamforming** for multi-passenger spectrum separation and **Vital Spectrum Feature-Driven Machine Learning**.

## Key Features & System Design Philosophy (核心功能與設計理念)
- **60 GHz FMCW Physical Twin & Data Cube:** Simulates chirp waveform generation, free-space/in-cabin propagation, Fast-Time Range FFT, and Slow-Time sub-millimeter physiological phase extraction ($\Delta \phi(t) = \frac{4\pi x(t)}{\lambda}$).
- **Automotive SoC-Friendly Architecture (No Heavy DR-MUSIC):** High-complexity super-resolution algorithms (such as DR-MUSIC) require heavy eigenvalue decomposition that exceeds embedded automotive SoC limits. This project replaces heavy spectral estimators with **lightweight IIR filtering, spatial beamforming, and AI-driven noise suppression**.
- **AI Processing Chain Beyond Point Clouds:** Rather than relying solely on spatial radar point clouds (which cannot distinguish a static doll from a breathing infant), our pipeline integrates **Vital Spectrum Feature Extraction (Welch PSD)** with lightweight Machine Learning and closed-loop observation window control.
- **Spatial Beamforming for Multi-Passenger Spectrum Separation:** Steers virtual beams toward specific seat coordinates to decouple overlapping vital spectra from multiple passengers and suppress off-axis vehicle vibrations.

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

**Feature Space Distribution:**

<img width="1600" height="800" alt="image" src="https://github.com/user-attachments/assets/526cc831-9743-4500-8675-0a24f845284d" />


<img width="618" height="730" alt="Feature Space" src="https://github.com/user-attachments/assets/7f1f44e4-73c7-4fd9-9fd0-1580e525d360" />

**Classification Confusion Matrix:**

<img width="618" height="692" alt="Confusion Matrix" src="https://github.com/user-attachments/assets/6359ec5f-41f3-4087-aebc-c184779cfd37" />

**Performance Analysis & Sim2Real Insights:**
- **High Separability for Adult States:** The model achieved **96.2% (51/53)** accuracy for `Normal` and **100% (51/51)** accuracy for `Stress` (white off-diagonal cells indicate zero false positives). The feature space plot confirms that adult vital signs form distinct, well-separated clusters.
- **Edge Case Discovery (`Baby/CPD` Limitation):** Classification accuracy dropped to **47.8% (22/46)** for the `Baby(CPD)` class, with 24 samples misclassified as adult states. Physically, because an infant's chest displacement (1.5 mm) is minuscule compared to vehicle sway (10 mm) and ambient cabin clutter, an unsteered single-channel receiver allows full-cabin noise and multi-passenger cross-talk to hijack the spectral peak finder.
- **The Value of the Digital Twin:** Instead of discovering this fatal CPD blind spot during real-vehicle deployment, our SIL Digital Twin safely exposed the physical boundary of unsteered 1D frequency filtering, directly motivating our Phase 5 spatial beamforming architecture.

---

## Current Progress: Phase 5 - Targeted Beamforming for Multi-Passenger Vital Spectrum Separation (空間波束指向與多乘員生命頻譜剝離)
In a realistic multi-passenger cabin, vital signals from multiple occupants (e.g., an adult driver and a rear-seat infant) and severe vehicle vibrations overlap simultaneously in both time and frequency domains. Furthermore, computationally heavy super-resolution estimators (such as DR-MUSIC) are prohibitive for real-time execution on automotive SoCs.

To resolve the Phase 4 CPD failure and decouple multiple passengers within SoC constraints, we implemented **Targeted Digital Beamforming** tightly coupled with our **Vital Spectrum AI Processing Chain**:
1. **Seat-Specific Spatial Beam Steering:** Utilizing a standard 4-RX automotive antenna array (λ/2 spacing), the system steers a spatial beam toward the specific seat coordinate of the infant (+15°) while placing a spatial null toward the strong interfering adult driver (-20°).
2. **Multi-Passenger Vital Spectrum Decoupling:** By extracting the slow-time physiological phase exclusively from the steered +15° spatial bin, the infant's weak micro-vital spectrum is cleanly separated from the adult's respiration clutter and fed into the PSD feature extractor.

### Phase 5 Results: Time-Domain Recovery & Vital Spectrum Separation

<img width="2352" height="1140" alt="image" src="https://github.com/user-attachments/assets/c3ef9b19-2f0e-4b8c-90cf-ab41ba48a2d3" />


**Engineering & Physical Insights:**
- **1A. Before Beamforming (Top-Left):** Without spatial steering, the received phase (grey) is heavily corrupted by cross-talk from the adult driver (-20°, 5 mm breathing) and vehicle vibrations, failing to track the infant's 1.5 mm ground-truth waveform (red).
- **1B. After Steering Beam to +15° Seat (Bottom-Left):** Following a brief 0 - 2 s IIR bandpass filter transient response, the spatially steered signal (blue) suppresses off-axis interference and accurately reconstructs the infant's true physiological phase (red), including both the 0.4 Hz breathing wave and 2.2 Hz heartbeat ripples.
- **2. Vital Spectrum Separation for AI (Right):** 
  - **Before Steering (Grey Dashed Line):** The normalized spectrum is hijacked by the adult driver's strong breathing component near 0.25 Hz, completely masking the infant's signature and explaining the Phase 4 ML misclassifications.
  - **After Steering to +15° (Blue Solid Line):** The adult interference at 0.25 Hz is eliminated. The extracted vital spectrum clearly reveals the infant's true respiration peak at **0.40 Hz** and heartbeat peak at **2.20 Hz**, providing clean, high-dimensional spectral features for the downstream AI classifier.

---

## Gap Analysis & Future Roadmap (現狀與計畫目標差距及未來展望)
To bridge this SIL prototype with the final 2-year NYCU × Whetron industrial project goals (WP1–WP4), our upcoming development focuses on four key upgrades:

1. **Multi-Seat Automated Beam Scanning:** Expand fixed-angle steering to automated 2D Range-Angle FFT + CFAR detection, dynamically steering multiple digital beams to simultaneously isolate and monitor ≥ 2 passengers across all cabin seats.
2. **Enhanced AI Noise Suppression with Full Spectral Features:** Move beyond simple spectral peak-picking by feeding full **vital spectrum envelopes, spectral entropy, variance, and time-frequency representations** into lightweight neural networks (1D-CNN / MLP) and harmonic comb filters, enabling the AI model to directly learn and suppress residual motion artifacts and breathing harmonics on edge SoCs.
3. **Multi-Sensor Fusion (Camera + Radar + IMU) for 3–5 Min Early Warning:** Integrate cabin optical camera cues (head pose, eyelid closure PERCLOS) with 60 GHz radar physiological trends (Heart Rate Variability - HRV and respiratory rhythm shifts) alongside onboard IMU vibration compensation. This multi-modal AI fusion aims to achieve **3 to 5 minutes of early warning** prior to severe driver drowsiness or acute cardiopulmonary events.
4. **Real-Vehicle HIL & Hybrid Twin Calibration:** Connect this unified MATLAB processing pipeline to Whetron's 60 GHz radar hardware I/Q data cube and ECG ground truth (< 10 ms timestamp alignment) to calibrate the Level 2/3 cabin multipath digital twin.
