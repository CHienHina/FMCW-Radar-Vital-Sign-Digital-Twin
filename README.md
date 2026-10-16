# FMCW Radar Vital Sign Detection & Digital Twin Simulation

This project simulates a 60 GHz FMCW radar system for detecting passenger vital signs (breathing and heartbeat) inside a vehicle. It includes a digital twin physical model and basic DSP algorithms (Range FFT).

## Features (目前功能)
* 60 GHz FMCW waveform generation and free-space propagation.
* Static human target detection using manual Range FFT.
* Next Phase: Integrating dynamic micro-displacements (respiration + heartbeat) and Extended Kalman Filter (EKF) for noise reduction.

## Tools & Languages (使用工具)
* MATLAB
* Phased Array System Toolbox

## Result (模擬結果)
<img width="1684" height="1032" alt="image" src="https://github.com/user-attachments/assets/22fc08ea-361a-48c1-aa8b-0dcfa926211f" />

## Current Progress: Phase 2 
Successfully integrated the dynamic physiological model (breathing + heartbeat) with the FMCW radar simulation. 
* Implemented a slow-time observation loop (100 fps over 10 seconds).
* Constructed a Radar Data Cube by collecting beat signals (IF signals) across multiple chirps.
* Applied Range FFT and phase unwrapping algorithms to successfully extract the underlying physiological phase variations from the 0.8m range bin.

### Phase 2 Simulation Result: Phase Extraction
The following figure demonstrates the successful extraction of vital signs from the 60 GHz FMCW radar echo over a 10-second slow-time observation window:

<img width="1006" height="682" alt="image" src="https://github.com/user-attachments/assets/e6f644f2-ecf7-493f-9b30-668250ed6b80" />




**Signal Analysis:**
* **Low-Frequency Component (Respiration):** The large macroscopic oscillations (ranging from approximately -13 to 13 radians) clearly reflect the simulated 0.3 Hz breathing displacement.
* **High-Frequency Ripples (Heartbeat):** The subtle micro-variations superimposed on the main waveform accurately represent the 1.2 Hz heartbeat displacement (amplitude ~0.5 mm).
* **DSP Validation:** This result validates the Range FFT and phase unwrapping pipeline, successfully transforming raw IF beat signals (Data Cube) into a clean, continuous physiological phase variation graph.

## Current Progress: Phase 3 - Noise Injection & Signal Recovery
To simulate a realistic in-cabin environment, severe vehicle vibrations and random Gaussian noise were injected into the digital twin's displacement model. The raw extracted phase was heavily corrupted, making vital signs indistinguishable.

We implemented Digital Signal Processing (DSP) **Bandpass Filters** to isolate specific frequency bands:
* **Breathing Band:** 0.15 Hz - 0.5 Hz
* **Heartbeat Band:** 0.8 Hz - 2.0 Hz

**Phase 3 Results:**
<img width="1386" height="1066" alt="image" src="https://github.com/user-attachments/assets/550c570e-d2c6-4fb0-9c02-5d6612fa3821" />




**Signal Analysis & DSP Performance:**
* **Raw Phase (Top):** The original radar phase is heavily distorted by simulated large-amplitude vehicle swaying and high-frequency random noise. The vital signs are completely submerged.
* **Respiration Recovery (Middle):** Applying a 0.15 - 0.5 Hz bandpass filter successfully eliminates the vehicle sway, revealing a clean 0.3 Hz breathing waveform.
* **Heartbeat Recovery (Bottom):** A subsequent 0.8 - 2.0 Hz bandpass filter accurately isolates the much weaker 1.2 Hz heartbeat signal from both the dominant respiration wave and the environmental noise.
* **Conclusion:** This effectively demonstrates the robustness of the DSP pipeline in separating micro-vital signs from severe in-cabin mechanical interference.

The DSP pipeline successfully suppressed the high-amplitude vehicle sway and high-frequency noise, accurately recovering both the respiration and heartbeat waveforms from the corrupted Data Cube.

## Current Progress (目前進度): Phase 4 - Machine Learning Classification & Closed-Loop Control
In this phase, we transitioned from basic signal extraction to **Intelligent State Recognition** and **Adaptive System Control**, directly addressing the real-world applications of In-Cabin Monitoring Systems (e.g., Driver Health Monitoring and Child Presence Detection - CPD).

### 1. Sim2Real Data Generation & Closed-Loop Control
To overcome the scarcity of real-world extreme physiological data, the Digital Twin engine was utilized to generate 150 synthetic samples across three distinct passenger states:
*   **Normal:** Standard adult resting heart and breath rates.
*   **Stress:** Elevated vital signs simulating driver fatigue or acute stress.
*   **Baby (CPD):** High-frequency, extremely low-amplitude displacements representing an infant left in a vehicle.

**Closed-Loop Feedback Mechanism:** We implemented a dynamic Signal-to-Clutter Ratio (SCR) evaluation. If the system detects severe environmental noise (e.g., heavy road bumps), it automatically triggers a closed-loop response, dynamically extending the observation window from 10 seconds to 15 seconds to ensure data integrity and avoid false readings.

### 2. Feature Extraction and ML Classification Results
Using Welch's Power Spectral Density (PSD) estimate, the dominant breathing and heartbeat frequencies were extracted as key features. These features were then fed into a **Random Forest Classifier**.

*(Note: Upload the scatter plot and confusion matrix images generated by MATLAB here and replace the placeholder links below)*

**Feature Space Distribution:**


<img width="600" alt="Feature Space" src="https://github.com/user-attachments/assets/8e54f7b0-58e4-409f-b458-3def99f21a6f" />



**Classification Confusion Matrix:**


<img width="600" alt="Confusion Matrix"  src="https://github.com/user-attachments/assets/fbb094ff-e07b-4cdd-a883-d236954b4373" />



**Performance Analysis:**
*   **High Separability:** The feature space plot demonstrates that the DSP pipeline effectively separates the micro-vital signs into distinct clusters despite severe simulated noise.
*   **Diagnostic Accuracy:** The Random Forest model achieved near-perfect classification accuracy across all states. The system can robustly differentiate between a stressed driver and a left-behind infant based solely on 60 GHz FMCW radar echoes.
*   **Conclusion:** The integration of the Physics-informed Digital Twin, DSP filtering, and Machine Learning establishes a complete, robust pipeline for next-generation intelligent in-cabin monitoring and safety systems.



