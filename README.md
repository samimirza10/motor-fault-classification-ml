# Motor Fault Classification using Machine Learning

## 📌 Project Overview
This project implements a machine learning-based condition monitoring system for a three-phase induction motor using current signal analysis and FFT-based feature extraction.

---

## ⚙️ Motor Specifications
- **Type:** Three-phase induction motor
- **Sampling rate:** 10,000 Hz
- **Data:** Current signals from Phase A, B, and C

---

## 🔍 Signal Analysis
We visualize the current signals to identify distinct patterns between states:

**Healthy Motor Signals**
<br>
![Healthy Motor Signals](figures/time_domain_analysis2.png)
<br><br>

**Broken Rotor Bar (BRB) Fault Signal**
<br>
![Broken Rotor Bar Fault Signal](figures/time_domain_analysis1.png)
<br><br>

**Direct Comparison: Healthy vs. Defect**
<br>
![Direct Comparison](figures/healthy_vs_defective.png)
<br><br>

---

## 🧠 Feature Extraction

### Time Domain
- Mean, RMS, standard deviation
- Signal amplitude behavior

### Frequency Domain (FFT)
**Focused frequency range:** 40–70 Hz

---

## 🏆 Results
Our comparative analysis shows that **Random Forest** and **KNN** provide the highest classification accuracy, achieving **99.95%**.

### Visual Results
**Confusion Matrix**
<br>
![Confusion Matrix](figures/Confusion_Matrix_Analysis.png)
<br><br>

**FFT Frequency Analysis**
<br>
![FFT Analysis](figures/FFT_Analysis.png)
<br><br>

### Performance Metrics
**Model Accuracy Comparison**
<br>
![Model Accuracy](figures/accuracy_comparison.png)
<br><br>

**Detailed Classification Metrics**
<br>
![Detailed Classification Metrics](figures/model_performance_metrics.png)
<br><br>

**Feature Importance Plot**
<br>
![Feature Importance](figures/feature_importance_plot.png)
<br><br>

### Key Achievements
- **High Accuracy:** Successfully developed an ML-based motor fault classifier with 99.8% accuracy.
- **Frequency Optimization:** Identified the optimal frequency range (40-70 Hz) for reliable bearing fault detection.
- **Algorithm Performance:** Random Forest and KNN proved to be the most effective algorithms.
- **Predictive Maintenance:** Enables non-invasive, real-time fault detection using only current sensors.

---

## 🔬 Key Insight
- **40–70 Hz range:** Supply frequency region.
- **100–400 Hz range:** Bearing fault harmonics.

---

## 🚀 Future Improvements
- CNN / LSTM deep learning models
- Multi-sensor fusion (vibration + thermal + current)
- Edge AI deployment
- Explainable AI (SHAP / LIME)
