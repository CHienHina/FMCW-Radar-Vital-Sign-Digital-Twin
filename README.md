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

## Current Progress (目前進度): Phase 2 
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

## Current Progress (目前進度): Phase 3 - Noise Injection & Signal Recovery
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

## Next Step (下一步挑戰): Phase 4
Explore Machine Learning techniques (e.g., SVM, Random Forest) to automatically classify the passenger's physiological state based on the extracted, filtered features, moving from signal extraction to intelligent state recognition.



