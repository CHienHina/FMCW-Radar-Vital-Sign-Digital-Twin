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
Generated a 60 GHz FMCW chirp waveform ($\text{Bandwidth} = 4\text{ GHz}$, yielding a range resolution of $\Delta R \approx 3.75\text{ cm}$) and applied manual Fast-Time **Range FFT** to accurately localize a static human target positioned at $0.8\text{ m}$ inside the cabin.

### Phase 1 Simulation Result: Range Profile
<img width="1684" height="1032" alt="Phase 1 Range FFT" src="https://github.com/user-attachments/assets/22fc08ea-361a-48c1-aa8b-0dcfa926211f" />

---

## Current Progress: Phase 2 - Dynamic Physiological Model & Phase Extraction (微動建模與相位解纏繞)
Successfully integrated the dynamic physiological chest micro-displacement model (breathing + heartbeat) with the 60 GHz FMCW radar simulation:
- Implemented a slow-time observation loop ($100\text{ fps}$ over a $10\text{ s}$ window, totaling $1,000\text{ chirps}$).
- Constructed a 2D **Radar Data Cube** by collecting intermediate-frequency (IF) beat signals across multiple chirps.
- Applied Fast-Time Range FFT and slow-time **Phase Unwrapping (`unwrap`)** to extract continuous physiological phase variations from the $0.8\text{ m}$ target range bin.

### Phase 2 Simulation Result: Phase Extraction
The following figure demonstrates the successful extraction of vital signs from the 60 GHz FMCW radar echo over a 10-second slow-time observation window:

<img width="1006" height="682" alt="Phase 2 Phase Extraction" src="https://github.com/user-attachments/assets/e6f644f2-ecf7-493f-9b30-668250ed6b80" />

**Signal Analysis:**
- **Low-Frequency Component (Respiration):** Because the 60 GHz wavelength is only $\lambda = 5\text{ mm}$, a $5\text{ mm}$ chest displacement induces phase shifts exceeding $[-\pi, \pi]$. Phase unwrapping successfully resolved these discontinuities, revealing macroscopic oscillations ($\approx -13\text{ to }13\text{ rad}$) that accurately reflect the simulated $0.3\text{ Hz}$ breathing wave.
- **High-Frequency Ripples (Heartbeat):** The subtle micro-variations superimposed on the main respiration wave accurately capture the $1.2\text{ Hz}$ heartbeat displacement ($\text{amplitude} \approx 0.5\text{ mm}$).
- **DSP Validation:** Validates the core Range FFT and phase unwrapping backbone, transforming raw IF beat signals into a continuous physiological phase signature.

---

## Current Progress: Phase 3 - Vehicle Vibration Injection & DSP Recovery (車體顛簸雜訊注入與頻帶分離)
To simulate realistic in-cabin failure modes during driving or idling, severe low-frequency vehicle vibrations ($0.1\text{ Hz}$, $\text{amplitude} = 20\text{ mm}$) and random Gaussian white noise were injected into the Digital Twin's displacement model. The raw extracted phase was heavily corrupted, making vital signs completely indistinguishable.

We implemented dual **IIR Bandpass Filters** to isolate specific physiological frequency bands while suppressing common-mode vehicle motion:
- **Breathing Band:** $0.15\text{ Hz} - 0.5\text{ Hz}$
- **Heartbeat Band:** $0.8\text{ Hz} - 2.0\text{ Hz}$

### Phase 3 Results: Noise Suppression & Waveform Recovery
<img width="1386" height="1066" alt="Phase 3 DSP Filtering" src="https://github.com/user-attachments/assets/550c570e-d2c6-4fb0-9c02-5d6612fa3821" />

**Signal Analysis & DSP Performance:**
- **Raw Phase (Top):** Heavily distorted by large-amplitude vehicle swaying ($\pm 50\text{ rad}$) and high-frequency random noise; micro-vital signs are completely submerged.
- **Respiration Recovery (Middle):** Applying the $0.15 - 0.5\text{ Hz}$ bandpass filter eliminates the $0.1\text{ Hz}$ vehicle sway, recovering a clean $0.3\text{ Hz}$ breathing waveform.
- **Heartbeat Recovery (Bottom):** A subsequent $0.8 - 2.0\text{ Hz}$ bandpass filter isolates the much weaker $1.2\text{ Hz}$ heartbeat signal ($\pm 2\text{ rad}$) from both the dominant respiration wave and environmental noise.
- **Conclusion:** Demonstrates the effectiveness of the front-end DSP pipeline in separating micro-vital signs from mechanical interference, providing clean time-domain inputs for subsequent spectral feature extraction.

---

## Current Progress: Phase 4 - AI Processing Chain, Vital Spectrum Features & Closed-Loop Control (AI 處理鏈、生命頻譜特徵擷取與閉環控制)
In this phase, we expanded the traditional DSP flow into an integrated **AI Processing Chain**, transitioning from raw signal extraction to **Intelligent State Recognition** and **Closed-Loop System Control** for Driver Health Monitoring and Child Presence Detection (CPD).

### 1. Sim2Real Synthetic Data Generation & Closed-Loop Feedback
To overcome the scarcity and ethical risks of collecting extreme real-world data (e.g., leaving an infant in a vibrating vehicle), the Digital Twin engine generated **150 synthetic samples** across three passenger states:
- **Normal:** Standard adult resting respiration ($0.25\text{ Hz}$, $5\text{ mm}$) and heart rate ($1.2\text{ Hz}$, $0.5\text{ mm}$).
- **Stress:** Elevated vital signs ($0.5\text{ Hz}$ breathing, $1.8\text{ Hz}$ heartbeat) simulating driver fatigue or acute physiological stress.
- **Baby (CPD):** High-frequency ($0.4\text{ Hz}$ breathing, $2.2\text{ Hz}$ heartbeat) but **extremely low-amplitude displacements** ($1.5\text{ mm}$ breathing, $0.2\text{ mm}$ heartbeat) representing a left-behind infant.

**Closed-Loop Feedback Mechanism:** The system continuously evaluates background noise and signal uncertainty. When severe environmental noise is detected (`noise_level > 0.0012`), the system triggers a closed-loop response, **dynamically extending the observation window from 10 seconds to 15 seconds** to accumulate sufficient slow-time energy before feature extraction.

### 2. Vital Spectrum Feature Extraction & ML Classification Results
Rather than training AI models solely on spatial point clouds, our AI processing chain computes **Welch's Power Spectral Density (PSD)** on the filtered phase signals to extract **Vital Spectrum Features** (dominant respiration/heartbeat spectral peaks and energy distribution). These features are fed into a lightweight **Random Forest Classifier**.

**Feature Space Distribution:**
<img width="618" height="730" alt="Feature Space" src="https://github.com/user-attachments/assets/7f1f44e4-73c7-4fd9-9fd0-1580e525d360" />

**Classification Confusion Matrix:**
<img width="618" height="692" alt="Confusion Matrix" src="https://github.com/user-attachments/assets/6359ec5f-41f3-4087-aebc-c184779cfd37" />

**Performance Analysis & Sim2Real Insights:**
- **High Separability for Adult States:** The model achieved **96.2% (51/53)** accuracy for `Normal` and **100% (51/51)** accuracy for `Stress` (white off-diagonal cells indicate zero false positives). The feature space plot confirms that adult vital signs form distinct, well-separated clusters.
- **Edge Case Discovery (`Baby/CPD` Limitation):** Classification accuracy dropped to **47.8% (22/46)** for the `Baby(CPD)` class, with 24 samples misclassified as adult states. Physically, because an infant's chest displacement ($1.5\text{ mm}$) is minuscule compared to vehicle sway ($10\text{ mm}$) and ambient cabin clutter, an unsteered single-channel receiver allows full-cabin noise and multi-passenger cross-talk to hijack the spectral peak finder.
- **The Value of the Digital Twin:** Instead of discovering this fatal CPD blind spot during real-vehicle deployment, our SIL Digital Twin safely exposed the physical boundary of unsteered 1D frequency filtering, directly motivating our Phase 5 spatial beamforming architecture.

---

## Current Progress: Phase 5 - Targeted Beamforming for Multi-Passenger Vital Spectrum Separation (空間波束指向與多乘員生命頻譜剝離)
In a realistic multi-passenger cabin, vital signals from multiple occupants (e.g., an adult driver and a rear-seat infant) and severe vehicle vibrations overlap simultaneously in both time and frequency domains. Furthermore, computationally heavy super-resolution estimators (such as DR-MUSIC) are prohibitive for real-time execution on automotive SoCs.

To resolve the Phase 4 CPD failure and decouple multiple passengers within SoC constraints, we implemented **Targeted Digital Beamforming** tightly coupled with our **Vital Spectrum AI Processing Chain**:
1. **Seat-Specific Spatial Beam Steering:** Utilizing a standard 4-RX automotive antenna array ($\lambda/2$ spacing), the system steers a spatial beam toward the specific seat coordinate of the infant ($+15^\circ$) while placing a spatial null toward the strong interfering adult driver ($-20^\circ$).
2. **Multi-Passenger Vital Spectrum Decoupling:** By extracting the slow-time physiological phase exclusively from the steered $+15^\circ$ spatial bin, the infant's weak micro-vital spectrum is cleanly separated from the adult's respiration clutter and fed into the PSD feature extractor.

### Phase 5 Results: Time-Domain Recovery & Vital Spectrum Separation
*(註：將上方修正版 MATLAB 程式碼跑出的新圖上傳至 GitHub 後，替換下方 `src` 連結即可)*

<img width="1100" alt="Phase 5 Beamforming and Vital Spectrum Separation" src="[請貼上修正後無重疊的新版 Phase 5 圖片連結]" />

**Engineering & Physical Insights:**
- **1A. Before Beamforming (Top-Left):** Without spatial steering, the received phase (grey) is heavily corrupted by cross-talk from the adult driver ($-20^\circ$, $5\text{ mm}$ breathing) and vehicle vibrations, failing to track the infant's $1.5\text{ mm}$ ground-truth waveform (red).
- **1B. After Steering Beam to $+15^\circ$ Seat (Bottom-Left):** Following a brief $0 - 2\text{ s}$ IIR bandpass filter transient response, the spatially steered signal (blue) suppresses off-axis interference and accurately reconstructs the infant's true physiological phase (red), including both the $0.4\text{ Hz}$ breathing wave and $2.2\text{ Hz}$ heartbeat ripples.
- **2. Vital Spectrum Separation for AI (Right):** 
  - **Before Steering (Grey Dashed Line):** The normalized spectrum is hijacked by the adult driver's strong breathing component near $0.25\text{ Hz}$, completely masking the infant's signature and explaining the Phase 4 ML misclassifications.
  - **After Steering to $+15^\circ$ (Blue Solid Line):** The adult interference at $0.25\text{ Hz}$ is eliminated. The extracted vital spectrum clearly reveals the infant's true respiration peak at **$0.40\text{ Hz}$** and heartbeat peak at **$2.20\text{ Hz}$**, providing clean, high-dimensional spectral features for the downstream AI classifier.

---

## Gap Analysis & Future Roadmap (現狀與計畫目標差距及未來展望)
To bridge this SIL prototype with the final 2-year NYCU $\times$ Whetron industrial project goals (WP1–WP4), our upcoming development focuses on four key upgrades:

1. **Multi-Seat Automated Beam Scanning:** Expand fixed-angle steering to automated 2D Range-Angle FFT + CFAR detection, dynamically steering multiple digital beams to simultaneously isolate and monitor $\ge 2$ passengers across all cabin seats.
2. **Enhanced AI Noise Suppression with Full Spectral Features:** Move beyond simple spectral peak-picking by feeding full **vital spectrum envelopes, spectral entropy, variance, and time-frequency representations** into lightweight neural networks (1D-CNN / MLP) and harmonic comb filters, enabling the AI model to directly learn and suppress residual motion artifacts and breathing harmonics on edge SoCs.
3. **Multi-Sensor Fusion (Camera + Radar + IMU) for 3–5 Min Early Warning:** Integrate cabin optical camera cues (head pose, eyelid closure PERCLOS) with 60 GHz radar physiological trends (Heart Rate Variability - HRV and respiratory rhythm shifts) alongside onboard IMU vibration compensation. This multi-modal AI fusion aims to achieve **3 to 5 minutes of early warning** prior to severe driver drowsiness or acute cardiopulmonary events.
4. **Real-Vehicle HIL & Hybrid Twin Calibration:** Connect this unified MATLAB processing pipeline to Whetron's 60 GHz radar hardware I/Q data cube and ECG ground truth (`< 10 ms` timestamp alignment) to calibrate the Level 2/3 cabin multipath digital twin.
