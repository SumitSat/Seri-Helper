# 🐛 Seri-Helper: User Guide & Frequently Asked Questions (FAQ)

Welcome to the Seri-Helper documentation! Sericulture is a highly precise agricultural science. This guide explains the technical and scientific concepts powering the Seri-Helper AI Yield Engine.

---

## 🌱 1. Mulberry Leaf & Nutrition

### Q: What does "Shoot Age (in days)" mean, and why does the app ask for it?
**A:** Mulberry plants are regularly pruned to encourage fresh branch growth. **Shoot Age** is the number of days since that last pruning.
As a shoot ages, the chemical composition of its leaves changes dramatically:
- **Young shoots (e.g., 30 days):** Leaves have very high moisture and protein, but low physical weight/biomass.
- **Older shoots (e.g., 70 days):** Leaves are thick, heavy, and rich in carbohydrates, but have lower moisture.
The app uses this age to accurately calculate the true nutritional value of the leaf you scanned.

### Q: What is "Leaf Position" and what do "P2-P4" or "P8+" mean?
**A:** The "P" stands for **Position** (or Phyllotaxy), which means counting the leaves from the top tip of the branch downwards.
- **P1, P2, P3, P4 (Top/Tender):** These are the youngest, softest leaves. They are packed with moisture and protein, making them the *only* leaves suitable for baby "chawki" worms (1st and 2nd instar).
- **P5 to P7 (Middle):** Medium mature leaves suitable for 3rd and 4th instars.
- **P8+ (Basal/Mixed):** These are the older, thicker, rougher leaves at the bottom. They are rich in carbohydrates and are strictly required for mature 5th instar worms just before they spin cocoons.

**Why the app asks:** If you feed tough P8 leaves to baby worms, they will starve. The app calculates your **Foliage Quality Index (FQI)** by ensuring you are feeding the correct leaf position to the correct stage of your silkworms.

---

## 🦋 2. Silkworm Rearing & Yield

### Q: What does "DFLs" stand for? (e.g., "60 kg / 100 DFLs")
**A:** **DFL** stands for **Disease Free Layings**.
In sericulture, farmers don't buy silkworms by weight; they buy egg clusters. One "laying" is the group of eggs (usually 400 to 500) laid by a single female silk moth. "Disease Free" means the supplier has microscopically tested the mother moth to guarantee the eggs aren't infected with deadly diseases like *Pébrine*.
**The Metric:** "60 kg / 100 DFLs" is the universal industry standard for measuring farm efficiency. It means: *"For every 100 clusters of eggs you reared, you successfully harvested 60 kilograms of raw silk cocoons."*

### Q: Why does the projected yield drop when I change the Temperature and Humidity sliders?
**A:** Silkworms are cold-blooded insects that are incredibly sensitive to micro-climates. The Yield Engine has a **Climate Conditions Index (CCI)** that simulates real-world environmental stress:
- **Temperature:** The absolute sweet spot is **24°C - 26°C**. If the temperature rises to 32°C, the worms become heat-stressed, lose their appetite, and become highly vulnerable to viral diseases like *Grasserie*. The app instantly drops your projected yield to reflect this biological reality.
- **Humidity:** The sweet spot is **75% - 85%**. If it drops to 40% (too dry), mulberry leaves wilt in the feeding bed before the worms can eat them. If it spikes to 95% (too wet), deadly fungal diseases like *Muscardine* spread rapidly.
By sliding those values, you are seeing a live simulation of exactly how many kilograms of silk you will lose if your rearing house is not properly climate-controlled.

---

## 🌍 3. Soil Health & Configuration

### Q: Why does the app say "Data not available" for some soil nutrients?
**A:** When the AI scans your physical Soil Health Card, it extracts exactly what is printed. If your testing laboratory did not test for specific micronutrients (like Zinc, Boron, or Moisture), the AI registers this as missing data. The app safely handles this by excluding those specific nutrients from the scoring formula rather than penalizing your farm with a "0" score.

### Q: What is the "Config Batch" button on the dashboard?
**A:** Before the app can predict your yield, it needs to know the specific parameters of your current silkworm batch. The Config Batch menu collects:
- **Silkworm Breed:** (e.g., CSR Bivoltine yields significantly more silk than local multivoltine breeds).
- **Hygiene & Disinfection:** Proper bed disinfection prevents up to 47% crop loss.
- **Fertilization:** Usage of foliar NPK sprays.
These answers generate your **BM-Factor (Breed & Management Multiplier)**, which heavily influences the final cocoon weight calculation.

---

## 💡 4. Troubleshooting

### Q: The Dashboard says "Awaiting Data" and won't show my prediction.
**A:** The V2 Yield Forecast requires three complete data points to run its algorithm. Check the tracker at the top of the dashboard. Ensure all three steps are green:
1. **Config Batch:** Fill out the rearing conditions.
2. **Leaf Scan:** Scan a leaf, enter its details, and save.
3. **Soil Scan:** Scan your soil report and confirm the values.
Once all three are completed, the yield dashboard will automatically unlock.
