# FoodToru - AI-Powered Meal Analysis App

FoodToru is a SwiftUI app that allows users to take photos of their meals and get AI-powered analysis including meal identification, calorie estimation, and nutritional information using Claude AI.

## Features

- 📸 **Camera Integration**: Take photos of your meals directly in the app
- 🤖 **AI Analysis**: Uses Claude AI to analyze meal photos and provide:
  - Meal name identification
  - Calorie estimation
  - Ingredient list
  - Nutritional analysis
- 💾 **Data Persistence**: Stores meal data locally using Core Data
- 📱 **Modern UI**: Clean, intuitive SwiftUI interface
- 📊 **Meal History**: View all your recorded meals with photos and details
- ⚙️ **Personalized Settings**: Enter your biometrics and exercise preferences
- 🔥 **Calorie Burn Estimation**: See how long it takes to burn off each meal's calories
- 🏃‍♂️ **Exercise Tracking**: Choose from various exercise types for accurate burn calculations

## Setup Instructions

### 1. Claude API Key Setup

1. Get your Claude API key from [Anthropic Console](https://console.anthropic.com/)
2. Open the app and tap the Settings gear icon
3. Tap "Set API Key" in the API Configuration section
4. Enter your Claude API key - it will be stored securely on your device
5. The app will automatically test the connection to verify your key works

### 2. Build and Run

1. Open `FoodToru.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

### 3. Permissions

The app will request camera permission when you first try to take a photo. Make sure to grant permission for the app to work properly.

## Usage

1. **Setup Profile** (Optional): Tap the settings gear icon to enter your biometrics and exercise preferences for personalized calorie burn estimates
2. **Take a Photo**: Tap the camera button in the toolbar to take a photo of your meal
3. **AI Analysis**: The app will automatically send the photo to Claude AI for analysis
4. **View Results**: Once analysis is complete, the meal will be added to your list with:
   - Meal name
   - Estimated calories
   - Calorie burn time estimate
   - Ingredients
   - Nutritional analysis
5. **View Details**: Tap on any meal to see detailed information including the full analysis and personalized burn time

## Technical Details

### Core Data Model
The app uses Core Data to store meal information with the following attributes:
- `timestamp`: When the meal was recorded
- `mealName`: Name of the meal identified by AI
- `calories`: Estimated calorie count
- `photoData`: Binary data of the meal photo
- `analysis`: Detailed nutritional analysis
- `ingredients`: List of identified ingredients

### Dependencies
- SwiftUI for the user interface
- Core Data for local data persistence
- UIKit for camera functionality
- Foundation for networking and data handling

### API Integration
The app integrates with Claude AI's API to provide intelligent meal analysis. The service sends base64-encoded images to Claude and receives structured JSON responses with meal information.

### Calorie Burn Calculation
The app uses the MET (Metabolic Equivalent of Task) system to calculate calorie burn times:
- **Personalized**: Uses user's height, weight, age, and preferred exercise type
- **Default Fallback**: Uses average person (70kg, 30 years old) walking at 3 mph if no biometrics provided
- **Exercise Types**: Supports 10 different exercise types with accurate MET values
- **Real-time Updates**: Burn time estimates update automatically when user changes settings

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Claude API key
- Camera access permission

## Troubleshooting

### API Request Failed Error

If you're getting "API request failed" errors, check the following:

1. **API Key Configuration**: Go to Settings and verify your API key is configured correctly
2. **Internet Connection**: Ensure you have a stable internet connection
3. **API Key Validity**: Verify your Claude API key is correct and active
4. **API Credits**: Check if you have sufficient API credits in your Anthropic account
5. **Debug Logs**: Check the Xcode console for detailed error messages

### Common Issues

- **Status 401**: Invalid API key - double-check your API key
- **Status 429**: Rate limit exceeded - wait a moment and try again
- **Status 400**: Invalid request format - the app will show detailed error
- **Network Error**: Check your internet connection

### Debug Information

The app now includes detailed logging. When you run the app in Xcode, check the console for:
- API request details
- Response status codes
- Error messages from Claude API
- Connection test results

## Notes

- Make sure you have a stable internet connection for AI analysis
- Photos are compressed to optimize API usage
- All data is stored locally on your device
- The app works offline for viewing previously analyzed meals
- The app will test the API connection when it starts up
