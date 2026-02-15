# Steps Reminder Widget - Project Description

## Overview

**Steps Reminder** is an intelligent fitness tracking widget for Garmin wearables that helps users stay on track with their daily step goals through adaptive learning and personalized notifications.

## 🎯 Problem Statement

Many fitness enthusiasts set daily step goals but struggle to maintain consistent progress throughout the day. By the time they realize they're behind schedule, it's often too late to catch up. Traditional step trackers only show current progress without providing proactive guidance.

## 💡 Solution

Steps Reminder uses machine learning to understand your unique walking patterns and provides timely alerts when you're falling behind your typical pace. Instead of rigid thresholds, the widget learns from 90 days of your activity history to predict where you should be at any given time.

## ✨ Key Features

### Adaptive Learning System
- **Historical Analysis**: Tracks up to 90 days of step data
- **Pattern Recognition**: Learns day-of-week and time-of-day patterns
- **Weighted Predictions**: Recent data weighted more heavily than older data
- **Personalized Thresholds**: Adapts to your individual walking habits

### Dual Operation Modes

#### Percentage Mode (Smart Learning)
- Compares actual progress against learned expectations
- Accounts for individual variations in daily patterns
- Provides 5% tolerance buffer to avoid false alerts

#### Absolute Mode (Traditional)
- Set specific time and step thresholds
- Example: Alert if fewer than 5,000 steps by noon
- Useful for consistent daily routines

### Multi-Channel Notifications
- **Vibration patterns**: Three-pulse alert sequence
- **Audio alerts**: High-priority tone
- **On-device display**: Real-time status updates
- **Smartphone integration**: Push notifications to connected phone

### Real-Time Monitoring
- Background checks every 20 minutes
- Battery-efficient temporal events
- Continuous learning from new data
- Auto-cleanup of old historical data

## 📊 User Interface

### Main Screen Display
1. **Current Progress**: Steps completed vs. daily goal
2. **Percentage Tracking**: Steps % and time % of day elapsed
3. **Learning Insights**: Expected progress with deviation indicator
4. **Status Indicator**: 
   - Green "On Track!" when meeting expectations
   - Red "Behind Schedule!" when falling behind

### Visual Feedback
- Color-coded status messages
- Clean, readable typography
- Center-aligned layout optimized for round displays
- Auto-refreshing every 10 seconds

## 🔧 Technical Architecture

### Technology Stack
- **Platform**: Garmin Connect IQ SDK 7.4.2+
- **Language**: Monkey C
- **API Level**: 5.2.0+
- **Target Device**: Fenix 7 Pro (expandable to other Garmin devices)

### Core Components

#### Application Layer (`steps_reminderApp.mc`)
- Background service management
- Historical data persistence
- Machine learning calculations
- Alert generation and delivery
- Storage management (max 90 days)

#### View Layer (`steps_reminderView.mc`)
- UI rendering and updates
- Real-time data display
- Timer-based refresh mechanism
- Status color logic

### Data Structure

```
Historical Record:
{
  "day": 1-7,              // Day of week
  "hour": 0-23,            // Hour of day
  "steps": Number,         // Actual steps
  "stepGoal": Number,      // Daily goal
  "stepsPercent": Float,   // Progress percentage
  "timePercent": Float,    // Day completion percentage
  "timestamp": Long        // Unix timestamp
}
```

### Learning Algorithm

1. **Data Collection**: Records steps/goal ratio every 20 minutes
2. **Pattern Matching**: Filters historical data by:
   - Same day of week
   - Similar time of day (±2 hours)
3. **Weighted Average**: 
   - Recent data: Higher weight (exponential decay: 0.95^days_old)
   - Older data: Lower weight
4. **Prediction**: Expected progress = Σ(historic_progress × weight) / Σ(weights)
5. **Alerting**: Trigger when actual < (expected - 5%)

### Permissions Required
- `Background`: Temporal event scheduling
- `Communications`: Phone notifications
- `PersistedContent`: Historical data storage
- `UserProfile`: Access to step goal and activity data

## 🌍 Internationalization

Fully bilingual support:
- **English**: Default language
- **Hebrew**: Complete RTL localization
- Dynamic string loading based on device settings

## 🎨 User Experience

### Configuration (Connect IQ Settings)
1. **Mode Selection**: Toggle between percentage and absolute modes
2. **Time Threshold**: 
   - Percentage mode: 0-100 (% of day)
   - Absolute mode: 0-1440 (minutes from midnight)
3. **Steps Threshold**:
   - Percentage mode: 0-100 (% of step goal)
   - Absolute mode: 0-50,000 (absolute step count)

### Default Settings
- Mode: Percentage (Smart Learning)
- Time Threshold: 50%
- Steps Threshold: 50%

### Use Case Examples

**Office Worker**
- Mode: Absolute
- Time: 960 (4:00 PM)
- Steps: 6,000
- Result: Alert if fewer than 6,000 steps by end of workday

**Fitness Enthusiast**
- Mode: Percentage (Learning)
- Lets the system learn their natural patterns
- Gets personalized alerts based on their typical pace

**Early Riser**
- Mode: Absolute
- Time: 720 (12:00 PM)
- Steps: 8,000
- Result: Alert if not halfway to goal by noon

## 📈 Future Enhancements

### Potential Features
- Multi-device support expansion
- Weather-based adjustments
- Calendar integration (skip alerts on rest days)
- Weekly pattern analysis
- Goal achievement predictions
- Customizable alert frequencies
- Sleep schedule awareness

### Technical Improvements
- Local ML model refinement
- Battery optimization
- Cloud backup of history
- Multi-goal tracking (distance, calories)

## 🛠️ Development

### Build Requirements
- Garmin Connect IQ SDK 7.4.2+
- VSCode with Monkey C extension
- Fenix 7 Pro device or simulator

### Project Structure
```
steps_reminder_widget/
├── manifest.xml              # App configuration
├── monkey.jungle             # Build config
├── source/
│   ├── steps_reminderApp.mc  # Core logic
│   └── steps_reminderView.mc # UI layer
└── resources/
    ├── properties.xml        # Default settings
    ├── settings/
    │   └── settings.xml      # User settings
    ├── strings/
    │   └── strings.xml       # English strings
    ├── drawables/
    │   └── launcher_icon.svg # App icon
    └── ../resources-heb/
        └── strings.xml       # Hebrew strings
```

## 📄 License

Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)

## 👨‍💻 Author

Created by **giamat13** for the Garmin developer community.

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

**Version**: 1.0  
**Last Updated**: February 2026  
**Compatibility**: Garmin Fenix 7 Pro  
**Category**: Health & Fitness