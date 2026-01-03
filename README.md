# Sparse, Noisy Ride Match Dataset

This work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](data/LICENSE.CC-BY-NC-SA) for everything in the `data/` directory ("the data") and [Apache 2.0](LICENSE.Apache-2.0) for everything else ("the code")

`SPDX-License-Identifier: Apache-2.0 OR CC-BY-NC-SA`

## 1. General Information

**Title:** Sparse, Noisy Ride Match Dataset  

**Author:**  
Gero Gerke  
Fachhochschule Aachen  
[gero.gerke@alumni.fh-aachen.de](mailto:gero.gerke@alumni.fh-aachen.de)

**Collection Period:** 2025-09-23 to 2025-10-31  
**Location:** Aachen, North Rhine-Westphalia, Germany  
**Sharing System:** [esel.ac Bikesharing e.V.](https://esel.ac/) is an association from Aachen, Germany that operates a free bicycle sharing system.

**Purpose:** Evaluation of map-matching algorithms using sparse, noisy bike sharing data paired with high-precision GPX ground truth. Collected for ongoing Bachelor's thesis at FH Aachen (2025-2026, not yet awarded or published).

## 2. Access and Citation

**Recommended Citation:**
```
@dataset{Gerke2025-SparseNoisyRideMatchDataset,
  author       = {Gerke, Gero},
  title        = {Sparse, Noisy Ride Match Dataset},
  year         = {2025},
  publisher    = {Fachhochschule Aachen},
  version      = {1.0},
  date         = {2025-01-03},
  url          = {https://github.com/Empty2k12/sparse-noisy-ride-match-dataset},
  urldate      = {2025-01-03},
  license      = {CC-BY-4.0},
  note         = {Dataset for BSc thesis, Fachhochschule Aachen},
  address      = {Aachen, North Rhine-Westphalia, Germany},
  keywords     = {bike-sharing, map-matching, GPS trajectories, noisy data, sparse data, ground truth, GPX},
  abstract     = {Empirical evaluation of map-matching algorithms using sparse, noisy bikesharing data paired with high-precision GPX ground truth. Contains esel.ac bikesharing ride history exports (browser geolocation) and corresponding high-precision GPX tracks collected via Open GPX Tracker on iPhone 13 mini. Collection period: 2025-09-23 to 2025-10-31. No outlier removal applied to preserve natural noise characteristics (accuracy ≥130 retained). Total 81KB JSON + 5434KB GPX data.},
  contact      = {gero.gerke@alumni.fh-aachen.de}
}
```

## 3. File Overview

| File Pattern | Description | Format | Size Estimate |
|--------------|-------------|--------|---------------|
| `*-esel.json` | Noisy ride data from esel.ac browser export | JSON array of points | 0.0-7.0KB per ride (81KB total) |
| `*.gpx` | High-precision ground truth trajectories | Standard GPX 1.1 | 0.0-362.0KB per ride (5434.0KB total) |

**Relationships:** Each `*-esel.json` pairs with corresponding `*.gpx` file for same ride instance (matched by timestamp/ride ID) and contained within a folder indicating date and time of collection.

**Version History:**

| Version | Date | Changes | Files Affected |
|---------|------|---------|----------------|
| 1.0 | 2026-01-03 | Initial release | All |

## 4. Methods

### 4.1 Collection
- **Noisy Data:** esel.ac Bikesharing e.V. ride history export (browser geolocation at rent/return).
- **Ground Truth:** [Open GPX Tracker](https://github.com/merlos/iOS-Open-GPX-Tracker) on iPhone 13 mini.
- **Conditions:** Real-world cycling (various times, weather).

### 4.2 Processing
1. Manual timestamp-based matching of esel.json ↔ GPX pairs.
2. Trimmed premature start/delayed end points.
3. **No outlier removal** (`accuracy ≥ 130` preserved for noise analysis).
4. No smoothing/interpolation applied.
5. No browser-collected geolocation based start and end positions removed (`accuracy == null`)

### 4.3 Instruments
| Component | Details |
|-----------|---------|
| Device | iPhone 13 mini (iOS 18) |
| GPX App | Open GPX Tracker |
| Accuracy | Unitless 0-255; ≥130 = unreliable per esel.ac analysis |

**Visualization:** [GitHub Pages](https://empty2k12.github.io/sparse-noisy-ride-match-dataset/) (basic trajectory mapping).

## 5. Data Formats

### 5.1 esel.ac JSON (`*-esel.json`)

| Variable | Type | Description | Units |
|----------|------|-------------|-------|
| `lat` | float | [WGS84](https://en.wikipedia.org/wiki/World_Geodetic_System) latitude | decimal degrees |
| `lon` | float | [WGS84](https://en.wikipedia.org/wiki/World_Geodetic_System) longitude | decimal degrees |
| `reported_at` | string | [ISO 8601 with timezone offset](https://en.wikipedia.org/wiki/ISO_8601) |  |
| `accuracy` | double or null | Confidence (0=best, 255=worst) | unitless |

**Example:**
```json
[{
    "reported_at": "2025-11-03T10:57:12+01:00",
    "accuracy": 71.0,
    "lat": 50.7592725,
    "lon": 6.082759
}]
```

### 5.2 GPX (`*.gpx`)
Standard [GPX 1.1](https://www.topografix.com/gpx/1/1/) track format.

## 6. Quality Control

| Procedure | Applied? | Notes |
|-----------|----------|-------|
| Outlier removal | No | Preserves natural noise (accuracy ≥130 retained) |
| Manual validation | Yes | All pairs inspected visually |
| Third-party data | No | Author-recorded only |

**Limitations:** Preliminary dataset for ongoing thesis research. No peer review completed.

***

**Contact:** [gero.gerke@alumni.fh-aachen.de](mailto:gero.gerke@alumni.fh-aachen.de) for questions or thesis updates.