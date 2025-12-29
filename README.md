# Mobile-Rice-Mold-Spoilage-Detection-System
Mobile rice mold detection system using MobileNet-V3 and SAM for Sri Lankan small-scale millers


## Project Overview

- **Architecture:** MobileNet-V3 + SAM (Segment Anything Model)
- **Classification:** 3-stage severity detection (healthy, early-risk, spoiled)
- **Platform:** Flutter mobile app (Android)
- **Target Devices:** Android smartphones

## Project Structure

├── dataset/          # Dataset preparation scripts
├── models/           # Model training and optimization
├── mobile_app/       # Flutter mobile application
├── backend/          # SAM segmentation API
├── docs/             # Documentation and progress logs
└── tests/            # Unit and integration tests


## Current Status

- [ ] Phase 1: Dataset Preparation 
- [ ] Phase 2: Model Development 
- [ ] Phase 3: Mobile Optimization 
- [ ] Phase 4: Bulk Segmentation 
- [ ] Phase 5: Mobile App Development 
- [ ] Phase 6: Local Validation 
- [ ] Phase 7: User Testing 

## Progress Log

See [docs/progress_log.md](docs/progress_log.md) for detailed updates.

## Setup Instructions

### Dataset Preparation
```bash
cd dataset/scripts
python recategorize_dataset.py
```

### Model Training
```bash
cd models/training
python train_mobilenet.py
```

### Mobile App
```bash
cd mobile_app
flutter pub get
flutter run
```

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Author

Kuluni Gamage- BSc Computing Final Year Project

## Acknowledgments

- GrainSet dataset by Fan et al. (2023)
- Meta AI's Segment Anything Model (SAM)
- MobileNet-V3 architecture
