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

<img width="1428" height="712" alt="image" src="https://github.com/user-attachments/assets/278a4c81-9fc6-4f39-a005-9448aba681e0" />


**Signal Analysis:**
* **Low-Frequency Component (Respiration):** The large macroscopic oscillations (ranging from approximately -13 to 13 radians) clearly reflect the simulated 0.3 Hz breathing displacement.
* **High-Frequency Ripples (Heartbeat):** The subtle micro-variations superimposed on the main waveform accurately represent the 1.2 Hz heartbeat displacement (amplitude ~0.5 mm).
* **DSP Validation:** This result validates the Range FFT and phase unwrapping pipeline, successfully transforming raw IF beat signals (Data Cube) into a clean, continuous physiological phase variation graph.

## Next Step (下一步挑戰): Phase 3
Real-world vehicle cabins are not perfectly stationary. The next objective is to inject vehicle vibration noise (simulating IMU error states) into the displacement model, and develop an **Extended Kalman Filter (EKF)** or apply Machine Learning techniques to robustly separate the vital signs from heavy environmental interference.
